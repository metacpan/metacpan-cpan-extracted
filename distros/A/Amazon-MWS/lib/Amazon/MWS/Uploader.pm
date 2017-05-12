package Amazon::MWS::Uploader;

use utf8;
use strict;
use warnings;

use DBI;
use Amazon::MWS::XML::Feed;
use Amazon::MWS::XML::Order;
use Amazon::MWS::Client;
use Amazon::MWS::XML::Response::FeedSubmissionResult;
use Amazon::MWS::XML::Response::OrderReport;
use Data::Dumper;
use File::Spec;
use DateTime;
use SQL::Abstract;
use Try::Tiny;
use Path::Tiny;
use Scalar::Util qw/blessed/;
use XML::Compile::Schema;

use Moo;
use MooX::Types::MooseLike::Base qw(:all);
use namespace::clean;

our $VERSION = '0.18';

use constant {
    AMW_ORDER_WILDCARD_ERROR => 999999,
    DEBUG => $ENV{AMZ_UPLOADER_DEBUG},
};

=head1 NAME

Amazon::MWS::Uploader -- high level agent to upload products to AMWS

=head1 DESCRIPTION

This module provide an high level interface to the upload process. It
has to keep track of the state to resume the uploading, which could
get stuck on the Amazon's side processing, so database credentials
have to be provided (or the database handle itself).

The table structure needed is defined and commented in sql/amazon.sql

=head1 SYNOPSIS

  my $agent = Amazon::MWS::Uploader->new(
                                         db_dsn => 'DBI:mysql:database=XXX',
                                         db_username => 'xxx',
                                         db_password => 'xxx',
                                         db_options => \%options
                                         # or dbh => $dbh,
  
                                         schema_dir => '/path/to/xml_schema',
                                         feed_dir => '/path/to/directory/for/xml',
  
                                         merchant_id => 'xxx',
                                         access_key_id => 'xxx',
                                         secret_key => 'xxx',
  
                                         marketplace_id => 'xxx',
                                         endpoint => 'xxx',
  
                                         products => \@products,
                                        );
  
  # say once a day, retrieve the full batch and send it up
  $agent->upload; 
  
  # every 10 minutes or so, continue the work started with ->upload, if any
  $agent->resume;


=head1 UPGRADE NOTES

When migrating from 0.05 to 0.06 please execute this SQL statement

 ALTER TABLE amazon_mws_products ADD COLUMN listed BOOLEAN;
 UPDATE amazon_mws_products SET listed = 1 WHERE status = 'ok';

When upgrading to 0.16, please execute this SQL statement:

 ALTER TABLE amazon_mws_products ADD COLUMN warnings TEXT;

=head1 ACCESSORS

The following keys must be passed at the constructor and can be
accessed read-only:

=over 4

=item dbh

The DBI handle. If not provided will be built using the following
self-describing accessor:

=item db_dsn

=item db_username

=item db_password

=item db_options

E.g.

  {
   mysql_enable_utf8 => 1,
  }

AutoCommit and RaiseError are set by us.

=cut

has db_dsn => (is => 'ro');
has db_password => (is => 'ro');
has db_username => (is => 'ro');
has db_options => (is => 'ro',
                   isa => AnyOf[Undef,HashRef],
                  );
has dbh => (is => 'lazy');

=item skus_warnings_modes

Determines how to treat warnings. This is a hash reference with the
code of the warning as key and one of the following modes as value:

=over 4

=item warn

Prints warning from Amazon with C<warn> function (default mode).

=item print

Prints warning from Amazon with C<print> function (default mode).

=item skip

Ignores warning from Amazon.

=back

=cut

has skus_warnings_modes => (is => 'rw',
                   isa => HashRef,
                   default => sub {{}},
               );

=item order_days_range

When calling get_orders, check the orders for the last X days. It
accepts an integer which should be in the range 1-30. Defaults to 7.

Keep in mind that if you change the default and you have a lot of
orders, you will get throttled because for each order we retrieve the
orderline as well.

DEVEL NOTE: a possible smart fix would be to store this object in the
order (or into a closure) and make the orderline a lazy attribute
which will call C<ListOrderItems>.

=cut

has order_days_range => (is => 'rw',
                         default => sub { 7 },
                         isa => sub {
                             my $days = $_[0];
                             die "Not an integer"
                               unless is_Int($days);
                             die "$days is out of range 1-30"
                               unless $days > 0 && $days < 31;
                         });

=item shop_id

You can pass an arbitrary identifier to the constructor which will be
used to keep the database records separated if you have multiple
amazon accounts. If not provided, the merchant id will be used, which
will work, but it's harder (for the humans) to spot and debug.

=cut

has shop_id => (is => 'ro');

has _unique_shop_id => (is => 'lazy');

sub _build__unique_shop_id {
    my $self = shift;
    if (my $id = $self->shop_id) {
        return $id;
    }
    else {
        return $self->merchant_id;
    }
}

=item debug

Print out additional information.

=item logfile

Passed to L<Amazon::MWS::Client> constructor.

=cut

has debug => (is => 'ro');

has logfile => (is => 'ro');

=item quiet

Boolean. Do not warn on timeouts and aborts (just print) if set to
true.

=cut

has quiet => (is => 'ro');

sub _build_dbh {
    my $self = shift;
    my $dsn = $self->db_dsn;
    die "Missing dns" unless $dsn;
    my $options = $self->db_options || {};
    # forse raise error and auto-commit
    $options->{RaiseError} = 1;
    $options->{AutoCommit} = 1;
    my $dbh = DBI->connect($dsn, $self->db_username, $self->db_password,
                           $options) or die "Couldn't connect to $dsn!";
    return $dbh;
}

=item purge_missing_products

If true, the first time C<products_to_upload> is called, products not
passed to the C<products> constructor will be purged from the
C<amazon_mws_products> table. Default to false.

This setting is DEPRECATED because can have some unwanted
side-effects. You are recommended to delete the obsoleted products
yourself.

=cut

has purge_missing_products => (is => 'rw');


=item reset_all_errors

If set to a true value, don't skip previously failed items and
effectively reset all of them.

Also, when the accessor is set for send_shipping_confirmation, try to
upload again previously failed orders.

=cut

has reset_all_errors => (is => 'ro');

=item reset_errors

A string containing a comma separated list of error codes, optionally
prefixed with a "!" (to reverse its meaning).

Example:

  "!6024,6023"

Meaning: reupload all the products whose error code is B<not> 6024 or
6023.

  "6024,6023"

Meaning: reupload the products whose error code was 6024 or 6023

=cut

has reset_errors => (is => 'ro',
                     isa => sub {
                         my $string = $_[0];
                         # undef/0/'' is fine
                         if ($string) {
                             die "reset_errors must be a comma separated list of error code, optionally prefixed by a '!' to negate its meaning"
                               if $string !~ m/^\s*!?\s*(([0-9]+)(\s*,\s*)?)+/;
                         }
                     });


has _reset_error_structure => (is => 'lazy');

sub _build__reset_error_structure {
    my $self = shift;
    my $reset_string = $self->reset_errors || '';
    $reset_string =~ s/^\s*//;
    $reset_string =~ s/\s*$//;
    return unless $reset_string;

    my $negate = 0;
    if ($reset_string =~ m/^\s*!\s*(.+)/) {
        $reset_string = $1;
        $negate = 1;
    }
    my %codes = map { $_ => 1 } grep { $_ } split(/\s*,\s*/, $reset_string);
    return unless %codes;
    return {
            negate => $negate,
            codes  => \%codes,
           };
}


=item force

Same as above, but only for the selected items. An arrayref is
expected here with the B<skus>.

=cut

has force => (is => 'ro',
              isa => ArrayRef,
             );


has _force_hashref => (is => 'lazy');

sub _build__force_hashref {
    my $self = shift;
    my %forced;
    if (my $arrayref = $self->force) {
        %forced = map { $_ => 1 } @$arrayref;
    }
    return \%forced;
}

=item limit_inventory

If set to an integer, limit the inventory to this value. Setting this
to 0 will disable it.

=item job_hours_timeout

If set to an integer, abort the job after X hours are elapsed since
the job was started. Default to 3 hours. Set to 0 to disable (not
recommended).

This doesn't affect jobs for order acknowledgements (C<order_ack>), see below.

=item order_ack_days_timeout

Order acknowlegments times out at different rate, because it's somehow
sensitive.

=cut

has job_hours_timeout => (is => 'ro',
                          isa => Int,
                          default => sub { 3 });

has order_ack_days_timeout => (is => 'ro',
                               isa => Int,
                               default => sub { 30 });

has limit_inventory => (is => 'ro',
                        isa => Int);

=item schema_dir

The directory where the xsd files for the feed building can be found.

=item feeder

A L<Amazon::MWS::XML::Feed> object. Lazy attribute, you shouldn't pass
this to the constructor, it is lazily built using C<products>,
C<merchant_id> and C<schema_dir>.

=item feed_dir

A working directory where to stash the uploaded feeds for inspection
if problems are detected.

=item schema

The L<XML::Compile::Schema> object, built lazily from C<feed_dir>

=item xml_writer

The xml writer, built lazily.

=item xml_reader

The xml reader, built lazily.

=cut

has schema_dir => (is => 'ro',
                   required => 1,
                   isa => sub {
                       die "$_[0] is not a directory" unless -d $_[0];
                   });

has feed_dir => (is => 'ro',
                 required => 1,
                 isa => sub {
                     die "$_[0] is not a directory" unless -d $_[0];
                 });

has schema => (is => 'lazy');

sub _build_schema {
    my $self = shift;
    my $files = File::Spec->catfile($self->schema_dir, '*.xsd');
    my $schema = XML::Compile::Schema->new([glob $files]);
    return $schema;
}

has xml_writer => (is => 'lazy');

sub _build_xml_writer {
    my $self = shift;
    return $self->schema->compile(WRITER => 'AmazonEnvelope');
}

has xml_reader => (is => 'lazy');

sub _build_xml_reader {
    my $self = shift;
    return $self->schema->compile(READER => 'AmazonEnvelope');
}


=item generic_feeder

Return a L<Amazon::MWS::XML::GenericFeed> object to build a feed using
the XML writer.

=cut

sub generic_feeder {
    my $self = shift;
    return Amazon::MWS::XML::GenericFeed->new(
                                              xml_writer => $self->xml_writer,
                                              merchant_id => $self->merchant_id,
                                             );
}


=item merchant_id

The merchant ID provided by Amazon.

=item access_key_id

Provided by Amazon.

=item secret_key

Provided by Amazon.

=item marketplace_id

L<http://docs.developer.amazonservices.com/en_US/dev_guide/DG_Endpoints.html>

=item endpoint

Ditto.

=cut

has merchant_id => (is => 'ro', required => 1);
has access_key_id => (is => 'ro', required => 1);
has secret_key => (is => 'ro', required => 1);
has marketplace_id => (is => 'ro', required => 1);
has endpoint => (is => 'ro', required => 1);

=item products

An arrayref of L<Amazon::MWS::XML::Product> objects, or anything that
(properly) responds to C<as_product_hash>, C<as_inventory_hash>,
C<as_price_hash>. See L<Amazon::MWS::XML::Product> for details.

B<This is set as read-write, so you can set the product after the
object construction, but if you change it afterward, you will get
unexpected results>.

This routine also check if the product needs upload and delete
disappeared products. If you are doing the check yourself, use
C<checked_products>.

=item checked_products

As C<products>, but no check is performed. This takes precedence.

=item sqla

Lazy attribute to hold the C<SQL::Abstract> object.

=cut

has products => (is => 'rw',
                 isa => ArrayRef);

has sqla => (
             is => 'ro',
             default => sub {
                 return SQL::Abstract->new;
             }
            );

has existing_products => (is => 'lazy');

sub _build_existing_products {
    my $self = shift;
    my $sth = $self->_exe_query($self->sqla->select(amazon_mws_products => [qw/sku
                                                                               timestamp_string
                                                                               status
                                                                               listed
                                                                               error_code
                                                                              /],
                                                    {
                                                     status => { -not_in => [qw/deleted/] },
                                                     shop_id => $self->_unique_shop_id,
                                                    }));
    my %uploaded;
    while (my $row = $sth->fetchrow_hashref) {
        $row->{timestamp_string} ||= 0;
        $uploaded{$row->{sku}} = $row;
    }
    return \%uploaded;
}

has products_to_upload => (is => 'lazy');

has checked_products => (is => 'rw', isa => ArrayRef);

sub _build_products_to_upload {
    my $self = shift;
    if (my $checked = $self->checked_products) {
        return $checked;
    }
    my $product_arrayref = $self->products;
    return [] unless $product_arrayref && @$product_arrayref;
    my @products = @$product_arrayref;
    my $existing = $self->existing_products;
    my @todo;
    foreach my $product (@products) {
        my $sku = $product->sku;
        if (my $exists = $existing->{$sku}) {
            # mark the item as visited
            $exists->{_examined} = 1;
        }
        print "Checking $sku\n" if $self->debug;
        next unless $self->product_needs_upload($product->sku, $product->timestamp_string);

        print "Scheduling product " . $product->sku . " for upload\n";
        if (my $limit = $self->limit_inventory) {
            my $real = $product->inventory;
            if ($real > $limit) {
                print "Limiting the $sku inventory from $real to $limit\n" if $self->debug;
                $product->inventory($limit);
            }
        }
        if (my $children = $product->children) {
            my @good_children;
            foreach my $child (@$children) {
                # skip failed children, but if the current status of
                # parent is failed, and we reached this point, retry.
                if ($existing->{$child} and
                    $existing->{$sku} and
                    $existing->{$sku}->{status} ne 'failed' and
                    $existing->{$child}->{status} eq 'failed') {
                    print "Ignoring failed variant $child\n";
                }
                else {
                    push @good_children, $child;
                }
            }
            $product->children(\@good_children);
        }
        push @todo, $product;
    }
    if ($self->purge_missing_products) {
        # nuke the products not passed
        # print Dumper($existing);
        my @deletions = map { $_->{sku} }
          grep { !$_->{_examined} }
            values %$existing;
        if (@deletions) {
            $self->delete_skus(@deletions);
        }
    }
    return \@todo;
}


=item client

An L<Amazon::MWS::Client> object, built lazily, so you don't have to
pass it.

=back

=cut

has client => (is => 'lazy');

sub _build_client {
    my $self = shift;
    my %mws_args = map { $_ => $self->$_ } (qw/merchant_id
                                               marketplace_id
                                               access_key_id
                                               secret_key
                                               debug
                                               logfile
                                               endpoint/);

    return Amazon::MWS::Client->new(%mws_args);
}

has _mismatch_patterns => (is => 'lazy', isa => HashRef);

sub _build__mismatch_patterns {
    my $self = shift;
    my $merchant_re = qr{\s+\((?:Merchant|Verkäufer):\s+'(.*?)'\s+/};
    my $amazon_re = qr{\s+.*?/\s*Amazon:\s+'(.*?)'\)};
    my %patterns = (
                    # informative only
                    asin => qr{ASIN(?:\s+überein)?\s+([0-9A-Za-z]+)},

                    shop_part_number => qr{part_number$merchant_re},
                    amazon_part_number => qr{part_number$amazon_re},

                    shop_title => qr{item_name$merchant_re},
                    amazon_title => qr{item_name$amazon_re},

                    shop_manufacturer => qr{manufacturer$merchant_re},
                    amazon_manufacturer => qr{manufacturer$amazon_re},

                    shop_brand => qr{brand$merchant_re},
                    amazon_brand => qr{brand$amazon_re},

                    shop_color => qr{color$merchant_re},
                    amazon_color => qr{color$amazon_re},

                    shop_size => qr{size$merchant_re},
                    amazon_size => qr{size$amazon_re},

                   );
    return \%patterns;
}


=head1 MAIN METHODS

=head2 upload

If the products is set, begin the routine to upload them. Because of
the asynchronous way AMWS works, at some point it will bail out,
saving the state in the database. You should reinstantiate the object
and call C<resume> on it every 10 minutes or so.

The workflow is described here:
L<http://docs.developer.amazonservices.com/en_US/feeds/Feeds_Overview.html>

This has to be done for each feed: Product, Inventory, Price, Image,
Relationship (for variants).

This method first generate the feeds in the feed directory, and then
calls C<resume>, which is in charge for the actual uploading.

=head2 resume

Restore the state and resume where it was left.

This method accepts an optional list of parameters. Each parameter may be:

=over 4

=item a scalar

This is considered a job id.

=item a hashref

This will be merged in the query to retrieve the pending jobs. A
sample usage could be:

  $upload->resume({ task => [qw/upload product_deletion/] });

to resume only those specific tasks.

=back

=head2 get_pending_jobs

Return the list of hashref with the pending jobs out of the database.
Accepts the same parameters as C<resume> (which actually calls this
method).

=cut

=head1 INTERNAL METHODS

=head2 prepare_feeds($type, { name => $feed_name, content => "<xml>..."}, { name => $feed_name2, content => "<xml>..."}, ....)

Prepare the feed of type $type with the feeds provided as additional
arguments.

Return the job id


=cut

sub _feed_job_dir {
    my ($self, $job_id, $create) = @_;
    die unless $job_id;
    my $shop_id = $self->_unique_shop_id;
    $shop_id =~ s/[^0-9A-Za-z_-]//g;
    die "The shop id without word characters results in an empty string"
      unless $shop_id;
    my $feed_root = File::Spec->catdir($self->feed_dir,
                                       $shop_id);
    if ($create) {
        mkdir $feed_root unless -d $feed_root;
    }

    my $feed_subdir = File::Spec->catdir($feed_root,
                                         $job_id);
    if ($create) {
        mkdir $feed_subdir unless -d $feed_subdir;
    }
    return $feed_subdir;
}

sub _feed_file_for_method {
    my ($self, $job_id, $feed_type) = @_;
    die unless $job_id && $feed_type;
    my $feed_subdir = $self->_feed_job_dir($job_id, "create");
    my $file = File::Spec->catfile($feed_subdir, $feed_type . '.xml');
    return File::Spec->rel2abs($file);
}

sub _slurp_file {
    my ($self, $file) = @_;
    open (my $fh, '<', $file) or die "Couldn't open $file $!";
    local $/ = undef;
    my $content = <$fh>;
    close $fh;
    return $content;
}

sub upload {
    my $self = shift;
    # create the feeds to be uploaded using the products
    my @products = @{ $self->products_to_upload };

    unless (@products) {
        print "No products, can't upload anything\n";
        return;
    }
    my $feeder = Amazon::MWS::XML::Feed->new(
                                             products => \@products,
                                             xml_writer => $self->xml_writer,
                                             merchant_id => $self->merchant_id,
                                            );
    my @feeds;
    foreach my $feed_name (qw/product
                              inventory
                              price
                              image
                              variants
                             /) {
        my $method = $feed_name . "_feed";
        if (my $content = $feeder->$method) {
            push @feeds, {
                          name => $feed_name,
                          content => $content,
                         };
        }
    }
    if (my $job_id = $self->prepare_feeds(upload => \@feeds)) {
        $self->_mark_products_as_pending($job_id, @products);
        return $job_id;
    }
    return;
}

sub _mark_products_as_pending {
    my ($self, $job_id, @products) = @_;
    die "Bad usage" unless $job_id;
    # these skus were cleared up when asking for the products to upload
    foreach my $p (@products) {
        my %identifier = (
                          sku => $p->sku,
                          shop_id => $self->_unique_shop_id,
                         );
        my %data = (
                    amws_job_id => $job_id,
                    status => 'pending',
                    warnings => '', # clear out
                    timestamp_string => $p->timestamp_string,
                   );
        my $check = $self
          ->_exe_query($self->sqla->select(amazon_mws_products => [qw/sku/],  { %identifier }));
        my $existing = $check->fetchrow_hashref;
        $check->finish;
        if ($existing) {
            $self->_exe_query($self->sqla->update(amazon_mws_products => \%data, \%identifier));
        }
        else {
            $self->_exe_query($self->sqla->insert(amazon_mws_products => { %identifier, %data }));
        }
    }
}


sub prepare_feeds {
    my ($self, $task, $feeds) = @_;
    die "Missing task ($task) and feeds ($feeds)" unless $task && $feeds;
    return unless @$feeds; # nothing to do
    my $job_id = $task . "-" . DateTime->now->strftime('%F-%H-%M-%S');
    my $job_started_epoch = time();

    $self->_exe_query($self->sqla
                      ->insert(amazon_mws_jobs => {
                                                   amws_job_id => $job_id,
                                                   shop_id => $self->_unique_shop_id,
                                                   task => $task,
                                                   job_started_epoch => $job_started_epoch,
                                                  }));

    # to complete the process, we need to fill out these five
    # feeds. every feed has the same procedure, as per
    # http://docs.developer.amazonservices.com/en_US/feeds/Feeds_Overview.html
    # so we put a flag on the feed when it is done. The processing
    # of the feed itself is tracked in the amazon_mws_feeds

    # TODO: we could pass to the object some flags to filter out results.
    foreach my $feed (@$feeds) {
        # write out the feed if we got something to do, and add a row
        # to the feeds.

        # when there is no content, no need to create a job for it.
        if (my $content = $feed->{content}) {
            my $name = $feed->{name} or die "Missing feed_name";
            my $file = $self->_feed_file_for_method($job_id, $name);
            open (my $fh, '>', $file) or die "Couldn't open $file $!";
            print $fh $content;
            close $fh;
            # and prepare a row for it

            my $insertion = {
                             feed_name => $name,
                             feed_file => $file,
                             amws_job_id => $job_id,
                             shop_id => $self->_unique_shop_id,
                            };
            $self->_exe_query($self->sqla
                              ->insert(amazon_mws_feeds => $insertion));
        }
    }
    return $job_id;
}


sub get_pending_jobs {
    my ($self, @args) = @_;
    my %additional;
    my @named_jobs;
    foreach my $arg (@args) {
        if (!ref($arg)) {
            push @named_jobs, $arg;
        }
        elsif (ref($arg) eq 'HASH') {
            # add the filters
            foreach my $key (keys %$arg) {
                if ($additional{$key}) {
                    die "Attempt to overwrite $key in the additional parameters!\n";
                }
                else {
                    $additional{$key} = $arg->{$key};
                }
            }
        }
        else {
            die "Argument must be either a scalar with a job name and/or "
              . "an hashref with additional filters!";
        }
    }
    if (@named_jobs) {
        $additional{amws_job_id} = { -in => \@named_jobs };
    }
    my ($stmt, @bind) = $self->sqla->select(amazon_mws_jobs => '*',
                                            {
                                             %additional,
                                             aborted => 0,
                                             success => 0,
                                             shop_id => $self->_unique_shop_id,
                                            },
                                            { -asc => 'job_started_epoch'});
    my $pending = $self->_exe_query($stmt, @bind);
    my %jobs;
    while (my $row = $pending->fetchrow_hashref) {
        $jobs{$row->{task}} ||= [];
        push @{$jobs{$row->{task}}}, $row;
    }
    my @out;
    foreach my $task (qw/product_deletion upload shipping_confirmation order_ack/) {
        if (my $list = delete $jobs{$task}) {
            if ($task eq 'order_ack') {
                for (1..2) {
                    push @out, pop @$list if @$list;
                }
            }
            elsif ($task eq 'shipping_confirmation') {
                while (@$list) {
                    push @out, pop @$list;
                }
            }
            else {
                push @out, @$list if @$list;
            }
        }
    }
    return @out;
}

sub resume {
    my ($self, @args) = @_;
    foreach my $row ($self->get_pending_jobs(@args)) {
        print "Working on $row->{amws_job_id}\n";
        # check if the job dir exists
        if (-d $self->_feed_job_dir($row->{amws_job_id})) {
            if (my $seconds_elapsed = $self->job_timed_out($row)) {
                $self->_print_or_warn_error("Timeout reached for $row->{amws_job_id}, aborting: "
                                            . Dumper($row));
                $self->cancel_job($row->{task}, $row->{amws_job_id},
                                  "Job timed out after $seconds_elapsed seconds");
                next;
            }
            $self->process_feeds($row);
        }
        else {
            warn "No directory " . $self->_feed_job_dir($row->{amws_job_id}) .
              " found, removing job id $row->{amws_job_id}\n";
            $self->cancel_job($row->{task}, $row->{amws_job_id},
                              "Job canceled due to missing feed directory");
        }
    }
}

=head2 cancel_job($task, $job_id, $reason)

Abort the job setting the aborted flag in C<amazon_mws_jobs> table.

=cut

sub cancel_job {
    my ($self, $task, $job_id, $reason) = @_;
    $self->_exe_query($self->sqla->update('amazon_mws_jobs',
                                          {
                                           aborted => 1,
                                           status => $reason,
                                          },
                                          {
                                           amws_job_id => $job_id,
                                           shop_id => $self->_unique_shop_id,
                                          }));

    # and revert the products' status
    my $status;
    if ($task eq 'product_deletion') {
        # let's pretend we were deleting good products
        $status = 'ok';
    }
    elsif ($task eq 'upload') {
        $status = 'redo';
    }
    if ($status) {
        print "Updating product to $status for products with job id $job_id\n";
        $self->_exe_query($self->sqla->update('amazon_mws_products',
                                              { status => $status  },
                                              {
                                               amws_job_id => $job_id,
                                               shop_id => $self->_unique_shop_id,
                                              }));
    }
}



=head2 process_feeds(\%job_row)

Given the hashref with the db row of the job, check at which point it
is and resume.

=cut

sub process_feeds {
    my ($self, $row) = @_;
    # print Dumper($row);
    # upload the feeds one by one and stop if something is blocking
    my $job_id = $row->{amws_job_id};
    print "Processing job $job_id\n";

    # query the feeds table for this job
    my ($stmt, @bind) = $self->sqla->select(amazon_mws_feeds => '*',
                                            {
                                             amws_job_id => $job_id,
                                             aborted => 0,
                                             success => 0,
                                             shop_id => $self->_unique_shop_id,
                                            },
                                            ['amws_feed_pk']);

    my $sth = $self->_exe_query($stmt, @bind);
    my $unfinished;
    while (my $feed = $sth->fetchrow_hashref) {
        last unless $self->upload_feed($feed);
    }
    $sth->finish;

    ($stmt, @bind) = $self->sqla->select(amazon_mws_feeds => '*',
                                         {
                                          shop_id => $self->_unique_shop_id,
                                          amws_job_id => $job_id,
                                         });

    $sth = $self->_exe_query($stmt, @bind);

    my ($total, $success, $aborted) = (0, 0, 0);

    # query again and check if we have aborted jobs;
    while (my $feed = $sth->fetchrow_hashref) {
        $total++;
        $success++ if $feed->{success};
        $aborted++ if $feed->{aborted};
    }

    # a job was aborted
    my $update;
    if ($aborted) {
        $update = {
                   aborted => 1,
                   status => 'Feed error',
                  };
        $self->_print_or_warn_error("Job $job_id aborted!\n");
    }
    elsif ($success == $total) {
        $update = { success => 1 };
        print "Job successful!\n";
        # if we're here, all the products are fine, so mark them as
        # such if it's an upload job
        if ($row->{task} eq 'upload') {
            $self->_exe_query($self->sqla->update('amazon_mws_products',
                                                  { status => 'ok',
                                                    listed_date => DateTime->now,
                                                    listed => 1,
                                                  },
                                                  {
                                                   amws_job_id => $job_id,
                                                   shop_id => $self->_unique_shop_id,
                                                  }));
        }
    }
    else {
        print "Job still to be processed\n";
    }
    if ($update) {
        $self->_exe_query($self->sqla->update(amazon_mws_jobs => $update,
                                              {
                                               amws_job_id => $job_id,
                                               shop_id => $self->_unique_shop_id,
                                              }));
    }
}

=head2 upload_feed($type, $feed_id);

Routine to upload the feed. Return true if it's complete, false
otherwise.

=cut

sub upload_feed {
    my ($self, $record) = @_;
    my $job_id = $record->{amws_job_id};
    my $type   = $record->{feed_name};
    my $feed_id = $record->{feed_id};
    print "Checking $type feed for $job_id\n";
    # http://docs.developer.amazonservices.com/en_US/feeds/Feeds_FeedType.html


    my %names = (
                 product => '_POST_PRODUCT_DATA_',
                 inventory => '_POST_INVENTORY_AVAILABILITY_DATA_',
                 price => '_POST_PRODUCT_PRICING_DATA_',
                 image => '_POST_PRODUCT_IMAGE_DATA_',
                 variants => '_POST_PRODUCT_RELATIONSHIP_DATA_',
                 order_ack => '_POST_ORDER_ACKNOWLEDGEMENT_DATA_',
                 shipping_confirmation => '_POST_ORDER_FULFILLMENT_DATA_',
                );

    die "Unrecognized type $type" unless $names{$type};

    # no feed id, it's a new batch
    if (!$feed_id) {
        print "No feed id found, doing a request for $job_id $type\n";
        my $feed_content = $self->_slurp_file($record->{feed_file});
        my $res;
        try {
            $res = $self->client
              ->SubmitFeed(content_type => 'text/xml; charset=utf-8',
                           FeedType => $names{$type},
                           FeedContent => $feed_content,
                           MarketplaceIdList => [$self->marketplace_id],
                          );
        }
        catch {
            warn "Failure to submit $type feed: \n";
            if (ref($_)) {
                if ($_->can('xml')) {
                    warn $_->xml;
                }
                else {
                    warn Dumper($_);
                }
            }
            else {
                warn $_;
            }
        };
        # do not register the failure on die, because in this case (no
        # response) there could be throttling, or network failure
        die unless $res;

        # update the feed_id row storing it and updating.
        if ($feed_id = $record->{feed_id} = $res->{FeedSubmissionId}) {
            $self->_exe_query($self->sqla
                              ->update(amazon_mws_feeds => $record,
                                       {
                                        amws_feed_pk => $record->{amws_feed_pk},
                                        shop_id => $self->_unique_shop_id,
                                       }));
        }
        else {
            # something is really wrong here, we have to die
            die "Couldn't get a submission id, response is " . Dumper($res);
        }
    }
    print "Feed is $feed_id\n";

    if (!$record->{processing_complete}) {
        if ($self->_check_processing_complete($feed_id, $type)) {
            # update the record and set the flag to true
            $self->_exe_query($self->sqla
                              ->update('amazon_mws_feeds',
                                       { processing_complete => 1 },
                                       {
                                        feed_id => $feed_id,
                                        shop_id => $self->_unique_shop_id,
                                       }));
        }
        else {
            print "Still processing\n";
            return;
        }
    }

    # check if we didn't already processed it
    if (!$record->{aborted} || !$record->{success}) {
        # we need a class to parse the result.
        my $result = $self->submission_result($feed_id);
        if ($result->is_success) {
            $self->_exe_query($self->sqla
                              ->update('amazon_mws_feeds',
                                       { success => 1 },
                                       {
                                        feed_id => $feed_id,
                                        shop_id => $self->_unique_shop_id,
                                       }));
            # if we have a success, print the warnings on the stderr.
            # if we have a failure, the warnings will just confuse us.

            if ($type eq 'order_ack') {
                # flip the confirmation bit
                $self->_exe_query($self->sqla->update(amazon_mws_orders => { confirmed => 1 },
                                                      { amws_job_id => $job_id,
                                                        shop_id => $self->_unique_shop_id }));
            }
            elsif ($type eq 'shipping_confirmation') {
                $self->_exe_query($self->sqla->update(amazon_mws_orders => { shipping_confirmation_ok => 1 },
                                                      { shipping_confirmation_job_id => $job_id,
                                                        shop_id => $self->_unique_shop_id }));
            }
            if (my $warn = $result->warnings) {
                if (my $warns = $result->skus_warnings) {
                    foreach my $w (@$warns) {
                        $self->_error_logger(warning => $w->{code},
                                             "$w->{sku}: $w->{error}");
                        # and register it in the db
                        if ($w->{sku} && $w->{error}) {
                            $self->_exe_query($self->sqla->update('amazon_mws_products',
                                                                  { warnings => "$job_id $w->{code} $w->{error}" },
                                                                  {
                                                                   sku => $w->{sku},
                                                                   shop_id => $self->_unique_shop_id,
                                                                  }));
                        }
                    }
                }
                else {
                    warn "$warn\n";
                }
            }
            return 1;
        }
        else {
            foreach my $err ($result->report_errors) {
                $self->_error_logger($err->{type},
                                     $err->{code},
                                     $err->{message});
            }
            $self->_exe_query($self->sqla
                              ->update('amazon_mws_feeds',
                                       {
                                        aborted => 1,
                                        errors => $result->errors,
                                       },
                                       {
                                        feed_id => $feed_id,
                                        shop_id => $self->_unique_shop_id,
                                       }));
            $self->register_errors($job_id, $result);
            
            if ($type eq 'order_ack') {
                $self->register_order_ack_errors($job_id, $result);
            }
            elsif ($type eq 'shipping_confirmation') {
                $self->register_ship_order_errors($job_id, $result);
            }
            
            # and we stop this job, has errors
            return 0;
        }
    }
    return $record->{success};
}

sub _exe_query {
    my ($self, $stmt, @bind) = @_;
    my $sth = $self->dbh->prepare($stmt);
    print $stmt, Dumper(\@bind) if DEBUG;
    eval {
        $sth->execute(@bind);
    };
    if ($@) {
        die "Failed to execute $stmt with params" . Dumper(\@bind);
    }
    return $sth;
}

sub _check_processing_complete {
    my ($self, $feed_id, $type) = @_;
    my $res;
    try {
        $res = $self->client->GetFeedSubmissionList;
    } catch {
        my $exception = $_;
        if (ref($exception) && $exception->can('xml')) {
            warn "checking processing complete error for $type $feed_id: " . $exception->xml;
        }
        else {
            warn "checking processing complete for $type $feed_id: " . Dumper($exception);
        }
    };
    die unless $res;
    print "Checking if the processing is complete for $type $feed_id\n"; # . Dumper($res);
    my $found;
    if (my $list = $res->{FeedSubmissionInfo}) {
        foreach my $feed (@$list) {
            if ($feed->{FeedSubmissionId} eq $feed_id) {
                $found = $feed;
                last;
            }
        }

        # check the result
        if ($found && $found->{FeedProcessingStatus} eq '_DONE_') {
            return 1;
        }
        elsif ($found) {
            print "Feed $type $feed_id still $found->{FeedProcessingStatus}\n";
            return;
        }
        else {
            # there is a remote possibility that in it in another
            # page, but it should be very unlikely, as we block the
            # process when the first one is not complete
            print "$feed_id not found in submission list\n";
            return;
        }
    }
    else {
        warn "No FeedSubmissionInfo found for $type $feed_id:" . Dumper($res);
        return;
    }
}

=head2 submission_result($feed_id)

Return a L<Amazon::MWS::XML::Response::FeedSubmissionResult> object
for the given feed ID.

=cut

sub submission_result {
    my ($self, $feed_id) = @_;
    my $xml;
    try {
        $xml = $self->client
          ->GetFeedSubmissionResult(FeedSubmissionId => $feed_id);
    } catch {
        my $exception = $_;
        if (ref($exception) && $exception->can('xml')) {
            warn "submission result error: " . $exception->xml;
        }
        else {
            warn "submission result error: " . Dumper($exception);
        }
    };
    die unless $xml;
    return Amazon::MWS::XML::Response::FeedSubmissionResult
      ->new(
            xml => $xml,
            xml_reader => $self->xml_reader,
           );
}

=head2 get_orders($from_date)

This is a self-contained method and doesn't require a product list.
The from_date must be a L<DateTime> object. If not provided, it will
the last week.

Returns a list of Amazon::MWS::XML::Order objects.

Beware that it's possible you get some items with 0 quantity, i.e.
single items cancelled. The application code needs to be prepared to
deal with such phantom items. You can check each order looping over
C<$order->items> checking for C<$item->quantity>.

=cut

sub get_orders {
    my ($self, $from_date) = @_;
    unless ($from_date) {
        $from_date = DateTime->now;
        $from_date->subtract(days => $self->order_days_range);
    }
    my @order_structs;
    my $res;
    try {
        $res = $self->client->ListOrders(
                                         MarketplaceId => [$self->marketplace_id],
                                         CreatedAfter  => $from_date,
                                        );
        push @order_structs, @{ $res->{Orders}->{Order} };
    }
    catch {
        die Dumper($_);
    };
    while (my $next_token = $res->{NextToken}) {
        # print "Found next token!\n";
        try {
            $res = $self->client->ListOrdersByNextToken(NextToken => $next_token);
            push @order_structs, @{ $res->{Orders}->{Order} };
        }
        catch {
            die Dumper($_);
        };
    }
    my @orders;
    foreach my $order (@order_structs) {
        my $amws_id = $order->{AmazonOrderId};
        die "Missing amazon AmazonOrderId?!" unless $amws_id;

        my $get_orderline = sub {
        # begin of the closure
        my $orderline;
        my @items;
        try {
            $orderline = $self->client->ListOrderItems(AmazonOrderId => $amws_id);
            push @items, @{ $orderline->{OrderItems}->{OrderItem} };
        }
        catch {
            my $err = $_;
            if (blessed($err) && $err->isa('Amazon::MWS::Exception::Throttled')) {
                die "Request is throttled. Consider to adjust order_days_range as documented at https://metacpan.org/pod/Amazon::MWS::Uploader#ACCESSORS";
            }
            else {
                die Dumper($err);
            }
        };
        while (my $next = $orderline->{NextToken}) {
            try {
                $orderline =
                  $self->client->ListOrderItemsByNextToken(NextToken  => $next);
                push @items, @{ $orderline->{OrderItems}->{OrderItem} };
            }
            catch {
                die Dumper($_);
            };
        }
        return \@items;
        # end of the closure
        };

        push @orders, Amazon::MWS::XML::Order->new(order => $order,
                                                   retrieve_orderline_sub => $get_orderline);
    }
    return @orders;
}

=head2 order_already_registered($order)

Check in the amazon_mws_orders table if we already registered this
order.

Return the row for this table (as an hashref) if present, nothing
underwise.

=cut

sub order_already_registered {
    my ($self, $order) = @_;
    die "Bad usage, missing order" unless $order;
    my $sth = $self->_exe_query($self->sqla->select(amazon_mws_orders => '*',
                                                    {
                                                     amazon_order_id => $order->amazon_order_number,
                                                     shop_id => $self->_unique_shop_id,
                                                    }));
    if (my $exists = $sth->fetchrow_hashref) {
        $sth->finish;
        return $exists;
    }
    else {
        return;
    }
}

=head2 acknowledge_successful_order(@orders)

Accept a list of L<Amazon::MWS::XML::Order> objects, prepare a
acknowledge feed with the C<Success> status, and insert the orders in
the database.

=cut

sub acknowledge_successful_order {
    my ($self, @orders) = @_;
    my @orders_to_register;
    foreach my $ord (@orders) {
        if (my $existing = $self->order_already_registered($ord)) {
            if ($existing->{confirmed}) {
                print "Skipping already confirmed order $existing->{amazon_order_id} => $existing->{shop_order_id}\n";
            }
            else {
                # it's not complete, so print out diagnostics
                warn "Order $existing->{amazon_order_id} uncompletely registered with id $existing->{shop_order_id}, please indagate why (skipping)\n" . Dumper($existing);
            }
        }
        else {
            push @orders_to_register, $ord;
        }
    }
    return unless @orders_to_register;

    my $feed_content = $self->acknowledge_feed(Success => @orders_to_register);
    # here we have only one feed to upload and check
    my $job_id = $self->prepare_feeds(order_ack => [{
                                                     name => 'order_ack',
                                                     content => $feed_content,
                                                    }]);
    # store the pairing amazon order id / shop order id in our table
    foreach my $order (@orders_to_register) {
        my %order_pairs = (
                           shop_id => $self->_unique_shop_id,
                           amazon_order_id => $order->amazon_order_number,
                           # this will die if we try to insert an undef order_number
                           shop_order_id => $order->order_number,
                           amws_job_id => $job_id,
                          );
        $self->_exe_query($self->sqla->insert(amazon_mws_orders => \%order_pairs));
    }
}


=head2 acknowledge_feed($status, @orders)

The first argument is usually C<Success>. The other arguments is a
list of L<Amazon::MWS::XML::Order> objects.

=cut


sub acknowledge_feed {
    my ($self, $status, @orders) = @_;
    die "Missing status" unless $status;
    die "Missing orders" unless @orders;

    my $feeder = $self->generic_feeder;

    my $counter = 1;
    my @messages;
    foreach my $order (@orders) {
        my $data = $order->as_ack_order_hashref;
        $data->{StatusCode} = $status;
        push @messages, {
                         MessageID => $counter++,
                         OrderAcknowledgement => $data,
                        };
    }
    return $feeder->create_feed(OrderAcknowledgement => \@messages);
}

=head2 delete_skus(@skus)

Accept a list of skus. Prepare a C<product_deletion> feed and update
the database.

=cut

sub delete_skus {
    my ($self, @skus) = @_;
    return unless @skus;
    print "Trying to purge missing items " . join(" ", @skus) . "\n";

    # delete only products which are not in pending status
    my $check = $self
      ->_exe_query($self->sqla
                   ->select('amazon_mws_products', [qw/sku status/],
                            {
                             sku => { -in => \@skus },
                             shop_id => $self->_unique_shop_id,
                            }));
    my %our_skus;
    while (my $p = $check->fetchrow_hashref) {
        $our_skus{$p->{sku}} = $p->{status};
    }
    my @checked;
    while (@skus) {
        my $sku = shift @skus;
        if (my $status = $our_skus{$sku}) {
            if ($status eq 'pending' or
                $status eq 'deleted') {
                print "Skipping $sku deletion, in status $status\n";
                next;
            }
        }
        else {
            warn "$sku not found in amazon_mws_products, deleting anyway\n";
        }
        push @checked, $sku;
    }
    @skus = @checked;

    unless (@skus) {
        print "Not purging anything\n";
        return;
    }
    print "Actually purging items " . join(" ", @skus) . "\n";

    my $feed_content = $self->delete_skus_feed(@skus);
    my $job_id = $self->prepare_feeds(product_deletion => [{
                                                            name => 'product',
                                                            content => $feed_content,
                                                           }] );
    # delete the skus locally
    $self->_exe_query($self->sqla->update('amazon_mws_products',
                                          {
                                           status => 'deleted',
                                           amws_job_id => $job_id,
                                          },
                                          {
                                           sku => { -in => \@skus },
                                           shop_id => $self->_unique_shop_id,
                                          }));
}

=head2 delete_skus_feed(@skus)

Prepare a feed (via C<create_feed>) to delete the given skus.

=cut

sub delete_skus_feed {
    my ($self, @skus) = @_;
    return unless @skus;
    my $feeder = $self->generic_feeder;
    my $counter = 1;
    my @messages;
    foreach my $sku (@skus) {
        push @messages, {
                         MessageID => $counter++,
                         OperationType => 'Delete',
                         Product => {
                                     SKU => $sku,
                                    }
                        };
    }
    return $feeder->create_feed(Product => \@messages);
}

sub register_order_ack_errors {
    my ($self, $job_id, $result) = @_;
    my @errors = $result->report_errors;
    # we hope to have just one error, but in case...
    my %update;
    if (@errors > 1) {
        my @errors_with_code = grep { $_->{code} } @errors;
        my $error_code = AMW_ORDER_WILDCARD_ERROR;
        if (@errors_with_code) {
            # pick just the first, the field is an integer
            $error_code = $errors_with_code[0]{code};
        }
        my $error_msgs  = join('\n', map { $_->{type} . ' ' . $_->{message} . ' ' . $_->{code} } @errors);
        %update = (
                   error_msg => $error_msgs,
                   error_code => $error_code,
                  );
    }
    elsif (@errors) {
        my $error = shift @errors;
        %update = (
                   error_msg => $error->{type} . ' ' . $_->{message} . ' ' . $_->{code},
                   error_code => $error->{code},
                  );
    }
    else {
        %update = (
                   error_msg => $result->errors,
                   error_code => AMW_ORDER_WILDCARD_ERROR,
                  );
    }
    if (%update) {
        $self->_exe_query($self->sqla->update('amazon_mws_orders',
                                              \%update,
                                              { amws_job_id => $job_id,
                                                shop_id => $self->_unique_shop_id }));
    }
    else {
        warn "register_order_ack_errors couldn't parse " . Dumper($result);
    }
    # then get the amazon order number and recheck
    my $sth = $self->_exe_query($self->sqla->select('amazon_mws_orders',
                                                    [qw/amazon_order_id
                                                        shop_order_id
                                                       /],
                                                    {
                                                     amws_job_id => $job_id,
                                                     shop_id => $self->_unique_shop_id,
                                                    }));
    my ($amw_order_number, $shop_order_id) = $sth->fetchrow_array;
    if ($sth->fetchrow_array) {
        warn "Multiple jobs found for $job_id in amazon_mws_orders!";
    }
    $sth->finish;
    if (my $status = $self->update_amw_order_status($amw_order_number)) {
        warn "$amw_order_number ($shop_order_id) has now status $status!\n";
    }
}

sub register_ship_order_errors {
    my ($self, $job_id, $result) = @_;
    # here we get the amazon ids,
    my @orders = $self->orders_in_shipping_job($job_id);
    my $errors = $result->orders_errors;
    # filter
    my @errors_with_order = grep { $_->{order_id} } @$errors;
    my %errs = map { $_->{order_id} => {job_id => $job_id, code => $_->{code}, error => $_->{error}} } @errors_with_order;

    foreach my $ord (@orders) {
        if (my $fault = $errs{$ord}) {
            $self->_exe_query($self->sqla->update('amazon_mws_orders',
                                                  {
                                                   shipping_confirmation_error => "$fault->{code} $fault->{error}",
                                                  },
                                                  {
                                                   amazon_order_id => $ord,
                                                   shipping_confirmation_job_id => $job_id,
                                                   shop_id => $self->_unique_shop_id,
                                                  }));
        }
        else {
            # this looks good
            $self->_exe_query($self->sqla->update('amazon_mws_orders',
                                                  {
                                                   shipping_confirmation_ok => 1,
                                                  },
                                                  {
                                                   amazon_order_id => $ord,
                                                   shipping_confirmation_job_id => $job_id,
                                                   shop_id => $self->_unique_shop_id
                                                  }));
        }
    }
}


=head2 register_errors($job_id, $result)

The first argument is the job ID. The second is a
L<Amazon::MWS::XML::Response::FeedSubmissionResult> object.

This method will update the status of the products (either C<failed>
or C<redo>) in C<amazon_mws_products>.

=head2 register_order_ack_errors($job_id, $result);

Same arguments as above, but for order acknowledgements.

=head2 register_ship_order_errors($job_id, $result);

Same arguments as above, but for shipping notifications.

=cut

sub register_errors {
    my ($self, $job_id, $result) = @_;
    # first, get the list of all the skus which were scheduled for this job
    # we don't have a products hashref anymore.
    # probably we could parse back the produced xml, but looks like an overkill.
    # just mark them as redo and wait for the next cron call.
    my @products = $self->skus_in_job($job_id);
    my $errors = $result->skus_errors;
    my @errors_with_sku = grep { $_->{sku} } @$errors;
    # turn it into an hash
    my %errs = map { $_->{sku} => {job_id => $job_id, code => $_->{code}, error => $_->{error}} } @errors_with_sku;

    foreach my $sku (@products) {
        if ($errs{$sku}) {
            $self->_exe_query($self->sqla->update('amazon_mws_products',
                                                  {
                                                   status => 'failed',
                                                   error_code => $errs{$sku}->{code},
                                                   error_msg => "$errs{$sku}->{job_id} $errs{$sku}->{code} $errs{$sku}->{error}",
                                                  },
                                                  {
                                                   sku => $sku,
                                                   shop_id => $self->_unique_shop_id,
                                                  }));
        }
        else {
            # this is good, mark it to be redone
            $self->_exe_query($self->sqla->update('amazon_mws_products',
                                                  {
                                                   status => 'redo',
                                                  },
                                                  {
                                                   sku => $sku,
                                                   shop_id => $self->_unique_shop_id,
                                                  }));
            print "Scheduling $sku for redoing\n";
        }
    }
}

=head2 skus_in_job($job_id)

Check the amazon_mws_product for the SKU which were uploaded by the
given job ID.

=cut

sub skus_in_job {
    my ($self, $job_id) = @_;
    my $sth = $self->_exe_query($self->sqla->select('amazon_mws_products',
                                                    [qw/sku/],
                                                    {
                                                     amws_job_id => $job_id,
                                                     shop_id => $self->_unique_shop_id,
                                                    }));
    my @skus;
    while (my $row = $sth->fetchrow_hashref) {
        push @skus, $row->{sku};
    }
    return @skus;
}

=head2 get_asin_for_eans(@eans)

Accept a list of EANs and return an hashref where the keys are the
eans passed as arguments, and the values are the ASIN for the current
marketplace. Max EANs: 5.x

http://docs.developer.amazonservices.com/en_US/products/Products_GetMatchingProductForId.html

=head2 get_asin_for_skus(@skus)

Same as above (with the same limit of 5 items), but for SKUs.

=head2 get_asin_for_sku($sku)

Same as above, but for a single sku. Return the ASIN or undef if not
found.

=head2 get_asin_for_ean($ean)

Same as above, but for a single ean. Return the ASIN or undef if not
found.

=cut

sub get_asin_for_skus {
    my ($self, @skus) = @_;
    return $self->_get_asin_for_type(SellerSKU => @skus);
}

sub get_asin_for_eans {
    my ($self, @eans) = @_;
    return $self->_get_asin_for_type(EAN => @eans);
}

sub _get_asin_for_type {
    my ($self, $type, @list) = @_;
    die "Max 5 products to get the asin for $type!" if @list > 5;
    my $client = $self->client;
    my $res;
    try {
        $res = $client->GetMatchingProductForId(IdType => $type,
                                                IdList => \@list,
                                                MarketplaceId => $self->marketplace_id);
    }
    catch { die Dumper($_) };
    my %ids;
    if ($res && @$res) {
        foreach my $product (@$res) {
            $ids{$product->{Id}} = $product->{Products}->{Product}->{Identifiers}->{MarketplaceASIN}->{ASIN};
        }
    }
    return \%ids;
}

sub get_asin_for_ean {
    my ($self, $ean) = @_;
    my $res = $self->get_asin_for_eans($ean);
    if ($res && $res->{$ean}) {
        return $res->{$ean};
    }
    else {
        return;
    }
}

sub get_asin_for_sku {
    my ($self, $sku) = @_;
    my $res = $self->get_asin_for_skus($sku);
    if ($res && $res->{$sku}) {
        return $res->{$sku};
    }
    else {
        return;
    }
}


=head2 get_product_category_data($ean)

Return the deep data structures returned by
C<GetProductCategoriesForASIN>.

=head2 get_product_categories($ean)

Return a list of category codes (the ones passed to
RecommendedBrowseNode) which exists on amazon.

=cut

sub get_product_category_data {
    my ($self, $ean) = @_;
    return unless $ean;
    my $asin = $self->get_asin_for_ean($ean);
    unless ($asin) {
        return;
    }
    my $res = $self->client
      ->GetProductCategoriesForASIN(ASIN => $asin,
                                    MarketplaceId => $self->marketplace_id);
    return $res;
}

=head2 get_product_category_names($ean)

Return a list of arrayrefs with the category paths. Beware that we
strip the first two parents, which euristically appear meaningless
(Category/Category).

If this is not a case, please report this as a bug and we'll find a
solution.

You can call C<get_product_category_data> to inspect the raw response
yourself.

=cut

sub get_product_category_names {
    my ($self, $ean) = @_;
    my $res = $self->get_product_category_data($ean);
    if ($res) {
        my @category_names;
        foreach my $cat (@$res) {
            my @list = $self->_parse_amz_cat($cat);
            if (@list) {
                push @category_names, \@list;
            }

        }
        return @category_names;
    }
    else {
        warn "ASIN exists but no categories found. Bug?\n";
        return;
    }
}

sub _parse_amz_cat {
    my ($self, $cat) = @_;
    my @path;
    while ($cat) {
        if ($cat->{ProductCategoryName}) {
            push @path, $cat->{ProductCategoryName};
        }
        $cat = $cat->{Parent};
    }
    @path = reverse @path;

    # the first two parents are Category/Category.
    if (@path >= 2) {
        splice(@path, 0, 2);
    }
    return @path;
}


sub get_product_categories {
    my ($self, $ean) = @_;
    my $res = $self->get_product_category_data($ean);
    if ($res) {
        my @ids = map { $_->{ProductCategoryId} } @$res;
        return @ids;
    }
    else {
        warn "ASIN exists but no categories found. Bug?\n";
        return;
    }
}


# http://docs.developer.amazonservices.com/en_US/products/Products_GetLowestOfferListingsForSKU.html

=head2 get_lowest_price_for_asin($asin, $condition)

Return the lowest price for asin, excluding ourselves. The second
argument, condition, is optional and defaults to "New".

If you need the full details, you have to call
$self->client->GetLowestOfferListingsForASIN yourself and make sense
of the output. This method is mostly a wrapper meant to simplify the
routine.

If we can't get any info, just return undef.

Return undef if no prices are found.

=head2 get_lowest_price_for_ean($ean, $condition)

Same as above, but use the EAN instead

=cut

sub get_lowest_price_for_ean {
    my ($self, $ean, $condition) = @_;
    return unless $ean;
    my $asin = $self->get_asin_for_ean($ean);
    return unless $asin;
    return $self->get_lowest_price_for_asin($asin, $condition);
}

sub get_lowest_price_for_asin {
    my ($self, $asin, $condition) = @_;
    die "Wrong usage, missing argument asin" unless $asin;
    my $listing;
    try { $listing = $self->client
      ->GetLowestOfferListingsForASIN(
                                      ASINList => [ $asin ],
                                      MarketplaceId => $self->marketplace_id,
                                      ExcludeMe => 1,
                                      ItemCondition => $condition || 'New',
                                     );
    }
    catch { die Dumper($_) };

    return unless $listing && @$listing;
    my $lowest;
    foreach my $item (@$listing) {
        my $current = $item->{Price}->{LandedPrice}->{Amount};
        $lowest ||= $current;
        if ($current < $lowest) {
            $lowest = $current;
        }
    }
    return $lowest;
}

=head2 shipping_confirmation_feed(@shipped_orders)

Return a feed string with the shipping confirmation. A list of
L<Amazon::MWS::XML::ShippedOrder> object must be passed.

=cut

sub shipping_confirmation_feed {
    my ($self, @shipped_orders) = @_;
    die "Missing Amazon::MWS::XML::ShippedOrder argument" unless @shipped_orders;
    my $feeder = $self->generic_feeder;
    my $counter = 1;
    my @messages;
    foreach my $order (@shipped_orders) {
        push @messages, {
                         MessageID => $counter++,
                         OrderFulfillment => $order->as_shipping_confirmation_hashref,
                        };
    }
    return $feeder->create_feed(OrderFulfillment => \@messages);

}

=head2 send_shipping_confirmation($shipped_orders)

Schedule the shipped orders (an L<Amazon::MWS::XML::ShippedOrder>
object) for the uploading.

=head2 order_already_shipped($shipped_order)

Check if the shipped orders (an L<Amazon::MWS::XML::ShippedOrder> was
already notified as shipped looking into our table, returning the row
with the order.

To see the status, check shipping_confirmation_ok (already done),
shipping_confirmation_error (faulty), shipping_confirmation_job_id (pending).

=cut

sub order_already_shipped {
    my ($self, $order) = @_;
    my $condition = $self->_condition_for_shipped_orders($order);
    my $sth = $self->_exe_query($self->sqla->select(amazon_mws_orders => '*', $condition));
    if (my $row = $sth->fetchrow_hashref) {
        die "Multiple results found in amazon_mws_orders for " . Dumper($condition)
          if $sth->fetchrow_hashref;
        return $row;
    }
    else {
        return;
    }
}

sub send_shipping_confirmation {
    my ($self, @orders) = @_;
    my @orders_to_notify;
    foreach my $ord (@orders) {
        if (my $report = $self->order_already_shipped($ord)) {
            if ($report->{shipping_confirmation_ok}) {
                print "Skipping ship-confirm for order $report->{amazon_order_id} $report->{shop_order_id}: already notified\n";
            }
            elsif (my $error = $report->{shipping_confirmation_error}) {
                if ($self->reset_all_errors) {
                    warn "Submitting again previously failed job $report->{amazon_order_id} $report->{shop_order_id}\n";
                    push @orders_to_notify, $ord;
                }
                else {
                    warn "Skipping ship-confirm for order $report->{amazon_order_id} $report->{shop_order_id} with error $error\n";
                }
            }
            elsif ($report->{shipping_confirmation_job_id}) {
                print "Skipping ship-confirm for order $report->{amazon_order_id} $report->{shop_order_id}: pending\n";
            }
            else {
                push @orders_to_notify, $ord;
            }
        }
        else {
            die "It looks like you are trying to send a shipping confirmation "
              . " without prior order acknowlegdement. "
                . "At least in the amazon_mws_orders there is no trace of "
                  . "$report->{amazon_order_id} $report->{shop_order_id}";
        }
    }
    return unless @orders_to_notify;
    my $feed_content = $self->shipping_confirmation_feed(@orders_to_notify);
    # here we have only one feed to upload and check
    my $job_id = $self->prepare_feeds(shipping_confirmation => [{
                                                                 name => 'shipping_confirmation',
                                                                 content => $feed_content,
                                                                }]);
    # and store the job id in the table
    foreach my $ord (@orders_to_notify) {
        $self->_exe_query($self->sqla->update(amazon_mws_orders => {
                                                                    shipping_confirmation_job_id => $job_id,
                                                                    shipping_confirmation_error => undef,
                                                                   },
                                              $self->_condition_for_shipped_orders($ord)));
    }
}

sub _condition_for_shipped_orders {
    my ($self, $order) = @_;
    die "Missing order" unless $order;
    my %condition = (shop_id => $self->_unique_shop_id);
    if (my $amazon_order_id = $order->amazon_order_id) {
        $condition{amazon_order_id} = $amazon_order_id;
    }
    elsif (my $order_id = $order->merchant_order_id) {
        $condition{shop_order_id} = $order_id;
    }
    else {
        die "Missing amazon_order_id or merchant_order_id";
    }
    return \%condition;
}


=head2 orders_waiting_for_shipping

Return a list of hashref with two keys, C<amazon_order_id> and
C<shop_order_id> for each order which is waiting confirmation.

This is implemented looking into amazon_mws_orders where there is no
shipping confirmation job id.

The confirmed flag (which means we acknowledged the order) is ignored
to avoid stuck order_ack jobs to prevent the shipping confirmation.

=cut

sub orders_waiting_for_shipping {
    my $self = shift;
    my $sth = $self->_exe_query($self->sqla->select('amazon_mws_orders',
                                                    [qw/amazon_order_id
                                                        shop_order_id/],
                                                    {
                                                     shop_id => $self->_unique_shop_id,
                                                     shipping_confirmation_job_id => undef,
                                                     # do not stop the unconfirmed to be considered
                                                     # confirmed => 1,
                                                    }));
    my @out;
    while (my $row = $sth->fetchrow_hashref) {
        push @out, $row;
    }
    return @out;
}

=head2 product_needs_upload($sku, $timestamp)

Lookup the product $sku with timestamp $timestamp and return the sku
if the product needs to be uploaded or can be safely skipped. This
method is stateless and doesn't alter anything.

=cut

sub product_needs_upload {
    my ($self, $sku, $timestamp) = @_;
    my $debug = $self->debug;
    return unless $sku;

    my $forced = $self->_force_hashref;
    # if it's forced, we have nothing to check, just pass it.
    if ($forced->{$sku}) {
        print "Forcing $sku as requested\n" if $debug;
        return $sku;
    }

    $timestamp ||= 0;
    my $existing = $self->existing_products;

    if (exists $existing->{$sku}) {
        if (my $exists = $existing->{$sku}) {

            my $status = $exists->{status} || '';

            if ($status eq 'ok') {
                if ($exists->{timestamp_string} eq $timestamp) {
                    return;
                }
                else {
                    return $sku;
                }
            }
            elsif ($status eq 'redo') {
                return $sku;
            }
            elsif ($status eq 'failed') {
                if ($self->reset_all_errors) {
                    return $sku;
                }
                elsif (my $reset = $self->_reset_error_structure) {
                    # option for this error was passed.
                    my $error = $exists->{error_code};
                    my $match = $reset->{codes}->{$error};
                    if (($match && $reset->{negate}) or
                        (!$match && !$reset->{negate})) {
                        # was passed !this error or !random , so do not reset
                        print "Skipping failed item $sku with error code $error\n" if $debug;
                        return;
                    }
                    else {
                        # otherwise reset
                        print "Resetting error for $sku with error code $error\n" if $debug;
                        return $sku;
                    }
                }
                else {
                    print "Skipping failed item $sku\n" if $debug;
                    return;
                }
            }
            elsif ($status eq 'pending') {
                print "Skipping pending item $sku\n" if $debug;
                return;
            }
            die "I shouldn't have reached this point with status <$status>";
        }
    }
    print "$sku wasn't uploaded so far, scheduling it\n" if $debug;
    return $sku;
}

=head2 orders_in_shipping_job($job_id)

Lookup the C<amazon_mws_orders> table and return a list of
C<amazon_order_id> for the given shipping confirmation job. INTERNAL.

=cut

sub orders_in_shipping_job {
    my ($self, $job_id) = @_;
    die unless $job_id;
    my $sth = $self->_exe_query($self->sqla->select(amazon_mws_orders => [qw/amazon_order_id/],
                                                    {
                                                     shipping_confirmation_job_id => $job_id,
                                                     shop_id => $self->_unique_shop_id,
                                                    }));
    my @orders;
    while (my $row = $sth->fetchrow_hashref) {
        push @orders, $row->{amazon_order_id};
    }
    return @orders;
}

=head2 put_product_on_error(sku => $sku, timestamp_string => $timestamp, error_code => $error_code, error_msg => $error)

Register a custom error for the product $sku with error $error and
$timestamp as the timestamp string. The error is optional, and will be
"shop error" if not provided. The error code will be 1 if not provided.

=cut

sub put_product_on_error {
    my ($self, %product) = @_;
    die "Missing sku" unless $product{sku};
    die "Missing timestamp" unless defined $product{timestamp_string};

    my %identifier = (
                      shop_id => $self->_unique_shop_id,
                      sku => $product{sku},
                     );
    my %errors = (
                  status => 'failed',
                  error_msg => $product{error_msg} || 'shop error',
                  error_code => $product{error_code} || 1,
                  timestamp_string => $product{timestamp_string},
                 );


    # check if we have it
    my $sth = $self->_exe_query($self->sqla
                                ->select('amazon_mws_products',
                                         [qw/sku/],  { %identifier }));
    if ($sth->fetchrow_hashref) {
        $sth->finish;
        print "Updating $product{sku} with error $product{error_msg}\n";
        $self->_exe_query($self->sqla->update('amazon_mws_products',
                                              \%errors, \%identifier));
    }
    else {
        print "Inserting $identifier{sku} with error $errors{error_msg}\n";
        $self->_exe_query($self->sqla
                          ->insert('amazon_mws_products',
                                   {
                                    %identifier,
                                    %errors,
                                   }));
    }
}


=head2 cancel_feed($feed_id)

Call the CancelFeedSubmissions API and abort the feed and the
belonging job if found in the list. Return the response, which
probably is not even meaningful. It is a big FeedSubmissionInfo with
the past feed submissions.

=cut

sub cancel_feed {
    my ($self, $feed) = @_;
    die "Missing feed id argument" unless $feed;
    # do the api call
    my $sth = $self->_exe_query($self->sqla
                                ->select(amazon_mws_feeds => [qw/amws_job_id/],
                                         {
                                          shop_id => $self->_unique_shop_id,
                                          feed_id => $feed,
                                          aborted => 0,
                                          success => 0,
                                          processing_complete => 0,
                                         }));
    my $feed_record = $sth->fetchrow_hashref;
    if ($feed_record) {
        $sth->finish;
        print "Found $feed in pending state\n";
        # abort it on our side
        $self->_exe_query($self->sqla
                          ->update('amazon_mws_feeds',
                                   {
                                    aborted => 1,
                                    errors => "Canceled by shop action",
                                   },
                                   {
                                    feed_id => $feed,
                                    shop_id => $self->_unique_shop_id,
                                   }));
        # and abort the job as well
        $self->_exe_query($self->sqla
                          ->update('amazon_mws_jobs',
                                   {
                                    aborted => 1,
                                    status => "Job aborted by cancel_feed",
                                   },
                                   {
                                    amws_job_id => $feed_record->{amws_job_id},
                                    shop_id => $self->_unique_shop_id,
                                   }));
        # and set the belonging products to redo
        $self->_exe_query($self->sqla
                          ->update('amazon_mws_products',
                                   {
                                    status => 'redo',
                                   },
                                   {
                                    amws_job_id => $feed_record->{amws_job_id},
                                    shop_id => $self->_unique_shop_id,
                                   }));
    }
    else {
        warn "No $feed found in pending list, trying to cancel anyway\n";
    }
    return $self->client->CancelFeedSubmissions(IdList => [ $feed ]);
}

sub _error_logger {
    my ($self, $error_or_warning, $error_code, $message) = @_;
    my $mode = 'warn';
    my $modes = $self->skus_warnings_modes;
    my $out_message = "$error_or_warning: $message ($error_code)\n";
    # hardcode 8008 as print
    $modes->{8008} = 'print';
    if (exists $modes->{$error_code}) {
        $mode = $modes->{$error_code};
    }
    if ($mode eq 'print') {
        print $out_message;
    }
    elsif ($mode eq 'warn') {
        warn $out_message;
    }
    elsif ($mode eq 'skip') {
        # do nothing
    }
    else {
        warn "Invalid mode $mode for $out_message";
    }
}

=head2 update_amw_order_status($amazon_order_number)

Check the order status on Amazon and update the row in the
amazon_mws_orders table.

=cut

sub update_amw_order_status {
    my ($self, $order) = @_;
    # first, check if it exists
    return unless $order;
    my $sth = $self->_exe_query($self->sqla->select('amazon_mws_orders',
                                                    '*',
                                                    {
                                                     amazon_order_id => $order,
                                                     shop_id => $self->_unique_shop_id,
                                                    }));
    my $order_ref = $sth->fetchrow_hashref;
    die "Multiple rows found for $order!" if $sth->fetchrow_hashref;
    print Dumper($order_ref);
    my $res = $self->client->GetOrder(AmazonOrderId => [$order]);
    my $amazon_order;
    if ($res && $res->{Orders}->{Order} && @{$res->{Orders}->{Order}}) {
        if (@{$res->{Orders}->{Order}} > 1) {
            warn "Multiple results for order $order: " . Dumper($res);
        }
        $amazon_order = $res->{Orders}->{Order}->[0];
    }
    else {
        warn "Order $order not found on amazon!"
    }
    print Dumper($amazon_order);
    my $obj = Amazon::MWS::XML::Order->new(order => $amazon_order);
    my $status = $obj->order_status;
    $self->_exe_query($self->sqla->update('amazon_mws_orders',
                                          { status => $status },
                                          {
                                           amazon_order_id => $order,
                                           shop_id => $self->_unique_shop_id,
                                          }));
    return $status;
}

=head2 get_products_with_error_code(@error_codes)

Return a list of hashref with the rows from C<amazon_mws_products> for
the current shop and the error code passed as argument. If no error
codes are passed, fetch all the products in error.

=head2 get_products_with_warnings

Returns a list of hashref, with C<sku> and C<warnings> as keys, for
each product in the shop which has the warnings set to something.

=cut

sub get_products_with_error_code {
    my ($self, @errcodes) = @_;
    my $where = { '>' => 0 };
    if (@errcodes) {
        $where = { -in => \@errcodes };
    }
    my $sth = $self->_exe_query($self->sqla
                                ->select('amazon_mws_products', '*',
                                         {
                                          status => { '!=' => 'deleted' },
                                          shop_id => $self->_unique_shop_id,
                                          error_code => $where,
                                         },
                                         [qw/error_code sku/]));
    my @records;
    while (my $row = $sth->fetchrow_hashref) {
        push @records, $row;
    }
    return @records;
}

sub get_products_with_warnings {
    my $self = shift;
    my $sth = $self->_exe_query($self->sqla
                                ->select('amazon_mws_products', '*',
                                         {
                                          status => 'ok',
                                          shop_id => $self->_unique_shop_id,
                                          warnings => { '!=' => '' },
                                         },
                                         [qw/sku warnings/]));
    my @records;
    while (my $row = $sth->fetchrow_hashref) {
        push @records, $row;
    }
    return @records;
}

=head2 mark_failed_products_as_redo(@skus)

Alter the status of the failed skus passed as argument from 'failed'
to 'redo' to trigger an update.

=cut

sub mark_failed_products_as_redo {
    my ($self, @skus) = @_;
    return unless @skus;
    $self->_exe_query($self->sqla->update('amazon_mws_products',
                                          {
                                           status => 'redo',
                                          },
                                          {
                                           shop_id => $self->_unique_shop_id,
                                           status => 'failed',
                                           sku => { -in => \@skus },
                                          }));
}

=head2 get_products_with_amazon_shop_mismatches(@errors)

Parse the amazon_mws_products and return an hashref where the keys are
the failed skus, and the values are hashrefs where the keys are the
mismatched fields and the values are hashrefs with these keys:

Mismatched fields may be: C<part_number>, C<title>, C<manufacturer>,
C<brand>, C<color>, C<size>

=over 4

=item shop

The value on the shop

=item amazon

The value of the amazon product

=item error_code

The error code

=back

E.g.

 my $mismatches = {12344 => {
                            part_number => {
                                            shop => 'XY',
                                            amazon => 'XYZ',
                                            error_code => '8541',
                                           },
                            title => {
                                            shop => 'ABC',
                                            amazon => 'DFG',
                                            error_code => '8541',
                                           },
                            },
                  .....
                  };

Optionally, if the error codes are passed to the argument, only those
errors are fetches.

=cut


sub get_products_with_amazon_shop_mismatches {
    my ($self, @errors) = @_;
    # so far only this code is for mismatches
    my %mismatches;
    my @faulty = $self->get_products_with_error_code(@errors);
    foreach my $product (@faulty) {
        # only if failed.
        next if $product->{status} ne 'failed';
        my $msg = $product->{error_msg};
        my $error_code = $product->{error_code};
        my $sku = $product->{sku};
        my $errors = $self->_parse_error_message_mismatches($msg);
        foreach my $key (keys %$errors) {
            # in this case, we are interested only in the pairs
            if (ref($errors->{$key}) eq 'HASH') {
                # we have the pair, so add the error code and report
                $errors->{$key}->{error_code} = $error_code;
                $mismatches{$sku}{$key} = $errors->{$key};
            }
        }
    }
    return \%mismatches;
}

=head2 get_products_with_mismatches(@errors)

Similar to C<get_products_with_amazon_shop_mismatches>, but instead
return an arrayref where each element is a hashref with all the info
collapsed.

The structures reported by C<get_products_with_amazon_shop_mismatches>
are flattened with an C<our_> and C<amazon_> prefix.

 our_part_number => 'XY',
 amazon_part_number => 'YZ',
 our_title = 'xx',
 amazon_title => 'yy',
 # etc.


=cut

sub get_products_with_mismatches {
    my ($self, @errors) = @_;
    my @faulty = $self->get_products_with_error_code(@errors);
    my @out;
    while (@faulty) {
        my $product = shift @faulty;
        my $errors = $self->_parse_error_message_mismatches($product->{error_msg});
        push @out, { %$product, %$errors };
    }
    return \@out;
}

sub _parse_error_message_mismatches {
    my ($self, $message) = @_;
    return {} unless $message;
    my %patterns = %{$self->_mismatch_patterns};
    my %out;
    foreach my $key (keys %patterns) {
        # if the pattern start we shop_ or amazon_, it's a pair
        my ($mismatch, $target);
        if ($key =~ /\A(shop|amazon)_(.+)/) {
            $target = $1;
            $mismatch = $2;
        }
        if ($message =~ $patterns{$key}) {
            my $value = $1;
            if ($target && $mismatch) {
                $out{$mismatch}{$target} = $value;
            }
            # and in any case store a scalar (and let's hope not to conflict)
            $out{$key} = $value;
        }
    }
    return \%out;
}

=head2 Order Report

To get this feature working, you need an C<amzn-envelope.xsd> with
OrderReport plugged in. Older versions are broken. Newer schema
versions may have missing Amazon.xsd file. So either you ask amazon to
give you a B<full set of xsd, which inclused OrderReport in
amzn-envelope.xsd> or you apply this patch to amzn-envelope.xsd:

  --- a/amzn-envelope.xsd  2014-10-27 10:26:19.000000000 +0100
  +++ b/amzn-envelope.xsd  2015-03-26 10:56:16.000000000 +0100
  @@ -23,2 +23,3 @@
          <xsd:include schemaLocation="Price.xsd"/>
  +    <xsd:include schemaLocation="OrderReport.xsd"/>
          <xsd:include schemaLocation="ProcessingReport.xsd"/>
  @@ -41,2 +42,3 @@
                                                          <xsd:enumeration value="OrderFulfillment"/>
  +                            <xsd:enumeration value="OrderReport"/>
                                                          <xsd:enumeration value="Override"/>
  @@ -83,2 +85,3 @@
                                                                  <xsd:element ref="OrderFulfillment"/>
  +                                <xsd:element ref="OrderReport"/>
                                                                  <xsd:element ref="Override"/>

=head3 get_unprocessed_orders

Return a list of objects with the orders.

=head3 get_unprocessed_order_report_ids

Return a list of unprocessed (i.e., which weren't acknowledged by us)
order report ids.

=cut

sub get_unprocessed_orders {
    my ($self) = @_;
    my @ids = $self->get_unprocessed_order_report_ids;
    my @orders = $self->get_order_reports_by_id(@ids);
    return @orders;
}

sub get_unprocessed_order_report_ids {
    my ($self, %options) = @_;
    my $res;
    try {
        $res = $self->client
          ->GetReportList(Acknowledged => 0,
                          ReportTypeList => ['_GET_ORDERS_DATA_'],
                          %options,
                         );
    } catch {
        _handle_exception($_);
    };

    my @reportids;

    # for now, do not ask for the next token, we will process them all
    # eventually

    if ($res and $res->{ReportInfo}) {
        foreach my $report (@{$res->{ReportInfo}}) {
            if (my $id = $report->{ReportId}) {
                push @reportids, $id;
            }
        }
    }
    return @reportids;
}


=head3 get_order_reports_by_id(@id_list)

The GetReport operation has a maximum request quota of 15 and a
restore rate of one request every minute.

=cut

sub get_order_reports_by_id {
    my ($self, @ids) = @_;
    my @orders;
    foreach my $id (@ids) {
        my $xml;
        try {
            $xml = $self->client->GetReport(ReportId => $id);
        } catch {
            _handle_exception($_);
        };
        if ($xml) {
            if (my @got = $self->_parse_order_reports_xml($xml)) {
                push @orders, @got;
            }
        }
    }
    return @orders;
}

sub _parse_order_reports_xml {
    my ($self, $xml) = @_;
    my @orders;
    my $data = $self->xml_reader->($xml);
    if (my $messages = $data->{Message}) {
        foreach my $message (@$messages) {
            if (my $order = $message->{OrderReport}) {
                my $order_object = Amazon::MWS::XML::Response::OrderReport->new(struct => $order);
                push @orders, $order_object;
            }
            else {
                die "Cannot found expected OrderReport in " . Dumper($message);
            }
        }
    }
    return @orders;
}


=head2 acknowledge_reports(@ids)

Mark the reports as processed.

=head2 unacknowledge_reports(@ids)

Mark the reports as not processed.

=cut

sub acknowledge_reports {
    my ($self, @ids) = @_;
    $self->_toggle_ack_reports(1, @ids);
}

sub unacknowledge_reports {
    my ($self, @ids) = @_;
    $self->_toggle_ack_reports(0, @ids);
}

sub _toggle_ack_reports {
    my ($self, $flag, @ids) = @_;
    return unless @ids;
    while (@ids) {
        # max 100 ids per run
        my @list = splice(@ids, 0, 100);
        try {
            $self->client->UpdateReportAcknowledgements(ReportIdList => \@list,
                                                        Acknowledged => $flag);
        } catch {
            _handle_exception($_);
        };
    }
    return;
}

sub _handle_exception {
    my ($err) = @_;
    if (blessed $err) {
        my $msg;
        if ( $err->isa('Amazon::MWS::Exception::Throttled') ) {
            $msg = $err->xml;
        }
        elsif ( $err->isa('Amazon::MWS::Exception')) {
            if (my $string = $err->error) {
                $msg = $string;
            }
            else {
                $msg = Dumper($err);
            }
        }
        else {
            $msg = Dumper($err);
        }
        if ( $err->isa('Amazon::MWS::Exception')) {
            $msg .= "\n" . $err->trace->as_string . "\n";
        }
        die $msg;
    }
    die $err;
}

=head2 job_timed_out($job_row) [INTERNAL]

Check if the hashref (which is a hashref of the amazon_mws_jobs row)
has timed out, comparing with the C<order_ack_days_timeout> and
C<job_hours_timeout> (depending on the job).


=cut

sub job_timed_out {
    my ($self, $job_row) = @_;
    my $task = $job_row->{task};
    die "Missing task in $job_row->{amws_job_id}" unless $task;
    my $started = $job_row->{job_started_epoch};
    die "Missing job_started_epoch in $job_row->{amws_job_id}" unless $started;
    my $now = time();
    my $timeout;
    if ($task eq 'order_ack') {
        $timeout = $self->order_ack_days_timeout * 60 * 60 * 24;
    }
    else {
        $timeout = $self->job_hours_timeout * 60 * 60;
    }
    die "Something is off, timeout not defined" unless defined $timeout;
    return unless $timeout;
    my $elapsed = $now - $started;
    if ($elapsed > $timeout) {
        return $elapsed;
    }
    else {
        return;
    }
}

sub _print_or_warn_error {
    my ($self, @args) = @_;
    my $action;
    if (@args) {
        if ($self->quiet) {
            $action = 'print';
            print @args;
        }
        else {
            $action = 'warn';
            warn @args;
        }
    }
    return ($action, @args);
}

=head2 purge_old_jobs($limit)

Eventually the jobs and feed tables grow and never get purged. You can
call this method to remove from the db all the feeds older than
C<order_ack_days_timeout> (30 by default).

To avoid too much load on the db, you can set the limit to purge the
jobs. Defaults to 500. Set it to 0 to disable it.

=cut

sub purge_old_jobs {
    my ($self, $limit) = @_;
    unless (defined $limit) {
        $limit = 500;
    }
    my $range = time() - $self->order_ack_days_timeout * 60 * 60 * 24;
    my @and = (
               task => [qw/product_deletion
                           upload/],
               job_started_epoch => { '<', $range },
               [ -or => {
                         aborted => 1,
                         success => 1,
                        },
               ],
              );
    if (my $shop_id = $self->shop_id) {
        push @and, shop_id => $shop_id;
    }

    my $sth = $self->_exe_query($self->sqla
                                ->select(amazon_mws_jobs => [qw/amws_job_id shop_id/],
                                         [ -and => \@and ] ));
    my @purge_jobs;
    my $count = 0;
    while (my $where = $sth->fetchrow_hashref) {
        if ($limit) {
            last if $count++ > $limit;
        }
        push @purge_jobs, $where;
    }
    $sth->finish;
    if (@purge_jobs) {
        $self->_exe_query($self->sqla->delete(amazon_mws_feeds => \@purge_jobs));
        $self->_exe_query($self->sqla->delete(amazon_mws_jobs  => \@purge_jobs));
        while (@purge_jobs) {
            my $feed = shift @purge_jobs;
            my $dir = path($self->feed_dir)->child($feed->{shop_id}, $feed->{amws_job_id});
            if ($dir->exists) {
                print "Removing " . $dir->canonpath . "\n"; # unless $self->quiet;
                $dir->remove_tree;
            }
            else {
                print "$dir doesn't exist\n";
            }
        }
    }
    else {
        print "Nothing to purge\n" unless $self->quiet;
    }
}

1;
