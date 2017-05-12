=head1 NAME

Data::Downloader::Feed

=head1 DESCRIPTION

Represents an RSS feed.

=cut

package Data::Downloader::Feed;
use Log::Log4perl qw/:easy/;
use String::Template qw/expand_string missing_values/;
use XML::LibXML;
use XML::LibXML::XPathContext;
use File::Temp;
use File::Copy qw/copy/;
use Time::HiRes qw/gettimeofday/;
use Params::Validate qw/validate validate_with/;
use Pod::Usage qw/pod2usage/;
use Data::Downloader::Utils qw/do_system_call/;
use if $Data::Downloader::useProgressBars, "Smart::Comments";
use strict;
use warnings;

our $defaultNamespaceURI;  # set once per execution; default namespace for items in feeds.
                           # "http://purl.org/rss/1.0/"

sub _get_from_xpath {
    my $self = shift;
    my ($xp,$context,$xpath) = @_;
    my $xpc = XML::LibXML::XPathContext->new($context);
    $xpc->registerNs(default => $defaultNamespaceURI) if $defaultNamespaceURI;
    my $value = $xpc->findvalue($xpath);
    TRACE "got $value from $xpath";
    LOGDIE "Got 'Bad credentials' for feed ".$self->name if $value && $value eq "Bad credentials";
    return $value;
}

sub _make_unique_filename {
    my $self = shift;
    return sprintf("%010d%06d%08d%06d",gettimeofday(),$$,int rand 1_000_000);
}

=head1 METHODS

=over

=item refresh

Refresh the data stored from this feed.

Parameters:

 - download : download the files, too?
 - fake : do a fake download?
 - from_file : use this file instead of the live feed?
 - any variables in the feed_template for this feed

Refreshing a feed may also :
 - remove files which are now obolete (because the feed has a urn for a different file)
 - update the symlinks for files whose metadata has changed

Also if both "user" and "password" are passed, they are treated specially
and sent as HTTP Basic auth credentials for the rss feed.

=cut

sub refresh {
    my $self = shift;

    my %args_tmp = @_;
    my $args;
    our $defaultNamespaceURI;

    $self->load unless ($self->repository && $self->repository_obj);
    DEBUG "refreshing feed ".$self->name.", repository is ".$self->repository_obj->name;

    # TODO store last_updated, skip already stored items.

    #
    # Get the xml
    #
    my $tmp = File::Temp->new;
    if (my $file = $args_tmp{from_file}) {
        DEBUG "using file $file";
        $args = validate(@_, { from_file => 1, download => 0, fake => 0,
                    map { $_ => 0} missing_values($self->feed_template) } );
        copy "$file", "$tmp" or die "Copying $file to $tmp failed : $!";
    } else {
        my @defaults = map { $_->name => $_->default_value } $self->feed_parameters;

        my %args = (@defaults, @_);

        # Handle these explicitly
        my ($username,$password);
        if ($args{user} && $args{password}) {
            $username = delete($args{'user'});
            $password = delete($args{'password'});
        }

        my @args = %args;

        $args = validate_with( 
                params  => \@args,
                spec    => { download => 0, fake => 0, map { $_ => 1} missing_values($self->feed_template) },
                on_fail => sub { 
                    my $msg = shift;
                    print qq|\n$msg\n|;

                    my %default_params   = map { $_->name => 1} $self->feed_parameters;
                    my %all_params       = map { $_ => 1 } missing_values($self->feed_template);
                    my %mandatory_params = map { $_ => 1 } grep(!defined $default_params{$_}, keys %all_params);

                    my %defaults = map { $_->name => $_->default_value } $self->feed_parameters;
                    my $default_params_str   = join("\n", map { $defaults{$_} ? "$_ ($defaults{$_})" : "$_ (optional)" } keys %defaults);
                    my $mandatory_params_str = join("\n", map{ "$_ (mandatory)" } keys %mandatory_params);

                    my $index;
                    my %args = map{ $_ => 1 } grep{!($index++ % 2)} @args;

                    my @non_valid = grep(! (defined $all_params{$_}), keys %args);
                    my $non_valid_str;
                    if (@non_valid) {
                        $non_valid_str = join("\n", @non_valid);
                        print qq|\nThe parameter(s) shown below are not valid:\n$non_valid_str\n|;
                    }

                    my @mandatory = grep(! defined $args{$_}, keys %mandatory_params);
                    my $mandatory_str;
                    if (@mandatory) {
                        $mandatory_str = join("\n", @mandatory);
                        print qq|\nThe mandatory parameter(s) shown below need to be specified:\n$mandatory_str\n\n|;
                    }


                    print <<_END;
Shown below are the parameters defined in the configuration (defaults/optional/mandatory in parenthesis):
$default_params_str
$mandatory_params_str

For additional documentation, type 'perldoc dado', or 'dado --help'.
_END

                    exit;
                }
        );

        my $url = expand_string($self->feed_template,$args);
        DEBUG "getting url $url";

        my @command = ("wget", "--quiet", "--no-check-certificate");
        if (defined($username) && defined($password)) {
            push(@command, "--http-user=$username", "--http-password=$password")
        }
        push(@command, "-O", "$tmp", $url);

        do_system_call(@command);
    }
    my $download = $args->{download};

    #
    # and extract things from it
    #
    my $xp = XML::LibXML->new()->parse_file($tmp->filename);
    my $i = 0;
    my @items = $xp->getElementsByTagName("item");              # RSS
    @items = $xp->getElementsByTagName("entry") unless @items;  # Atom
    @items = $xp->getElementsByTagName("atom:entry") unless @items;  # Atom
  ITEM:
    for my $item (@items) {  ### Extracting [===%       ]
        last if $args->{count} and $i++ > $args->{count}; # TODO omisips has an extra item
        $defaultNamespaceURI = ($item->namespaceURI || '') unless defined($defaultNamespaceURI);

        my %file;
        defined($_ = $self->file_source->urn_xpath)      and $file{urn}      = $self->_get_from_xpath($xp,$item,$_);
        defined($_ = $self->file_source->url_xpath)      and $file{url}      = $self->_get_from_xpath($xp,$item,$_);
        defined($_ = $self->file_source->md5_xpath)      and $file{md5}      = $self->_get_from_xpath($xp,$item,$_);
        defined($_ = $self->file_source->filename_xpath) and $file{filename} = $self->_get_from_xpath($xp,$item,$_);
        if (my $re = $self->file_source->filename_regex) {
            ($file{filename}) = $file{filename} =~ /$re/;
        }

#        $file{filename} ||= $self->_make_unique_filename;
	next ITEM unless ($file{filename});
        my $file = Data::Downloader::File->new(md5 => $file{md5}, filename => $file{filename});

        my $is_new;
        for my $field (keys %file) {
            $file->$field($file{$field});
            TRACE "setting $field to $file{$field}";
        }
        $file->repository($self->repository);
        if ($file->load(speculative => 1)) {
            DEBUG "found existing record for file ".($file->filename || $file->md5);
            # We need to see if there is another file with this urn, and if so, remove it.
            if ($file{urn} && (!defined($file->urn) or $file{urn} ne $file->urn)) {
                my $other_file = Data::Downloader::File->new(urn => $file{urn});
                if ($other_file->load_from_urn(speculative => 1) && 
		    ($other_file->id != $file->id)) {
		    INFO "Purging preexisting file with colliding urn ($file{urn})";
		    $other_file->purge or do {
			ERROR "Failed to purge preexisting file ".$file->filename;
			next ITEM;
		    };
		}
            }
        } elsif ($file->load_from_urn(speculative => 1)) {
            DEBUG "found existing record for urn ".($file->urn);
            # Since the filename is different, remove the old one and its symlinks.
            INFO "Removing file with matching urn: ".$file->urn;
            $file->remove;
            $file->load;
        } else {
            $is_new = 1;
            TRACE "new record for file ".$file->filename;
        }

        unless ($is_new) {
            $file->$_($file{$_}) for keys %file; # set all fields again.
        }
        $file->save or do {
	    ERROR $file->error;
	    next ITEM;
	};

        # Now get metadata
        my $fmd = Data::Downloader::FileMetadata->new(file => $file->id);
        $fmd->load(speculative => 1);
        for my $md_source ( $self->metadata_sources ) {
            my $datum = Data::Downloader::Metadatum->new(
                file  => $file->id,
                name  => $md_source->name,
            );
            $datum->load(speculative => 1);
            $datum->value($self->_get_from_xpath( $xp, $item, $md_source->xpath));
            $datum->save or do {
		ERROR $datum->error;
		next ITEM;
	    };
            my ($n,$v) = ($datum->name, $datum->value);
            $fmd->$n($v);
        }
        $fmd->save;

        if ($download && !$file->_already_downloaded) {
            $file->download( fake => $args->{fake}, skip_links => 1) or return;
        }
        $file->makelinks if $file->on_disk;
    }
    1;
}

=back

=head1 SEE ALSO

L<Rose::DB::Object>

L<Data::Downloader/SCHEMA>

=cut

1;

