package CPAN2RT;

=head1 NAME

CPAN2RT - CPAN to RT converter for rt.cpan.org service

=head1 DESCRIPTION

An utility and module with functions to import and update metadata
about CPAN distributions into RT DB using files available from each
CPAN mirror.

Comes with `cpan2rt` script.

=cut

use v5.8.3;
use strict;
use warnings;

our $VERSION = '0.03';

use Email::Address;
use List::Compare;
use CPAN::DistnameInfo;
use List::MoreUtils qw(uniq);

our $DEBUG = 0;
sub debug(&);

=head1 METHODS

=head2 new

Simple constructor that creates a hash based object and stores all
passed arguments inside it. Then L</init> is called.

=head3 options

=over 8

=item home - RT home dir, RTHOME is checked if empty and defaults to
"/opt/rt3".

=item debug - turn on ddebug output to STDERR.

=item mirror - CPAN mirror to fetch files from.

=back

=cut

sub new {
    my $proto = shift;
    my $self = bless { @_ }, ref($proto) || $proto;
    $self->init();
    return $self;
}

=head2 init

Called right after constructor, changes @INC, loads RT and initilize it.

See options in description of L</new>.

=cut

sub init {
    my $self = shift;

    my $home = ($self->{'home'} ||= $ENV{'RTHOME'} || '/opt/rt3');
    unshift @INC, File::Spec->catdir( $home, 'lib' );
    unshift @INC, File::Spec->catdir( $home, 'local', 'lib' );

    require RT;
    RT::LoadConfig();
    RT::Init();

    $DEBUG = $self->{'debug'};
}

sub sync_files {
    my $self = shift;
    my $mirror = shift || $self->{'mirror'} || 'ftp://ftp.funet.fi/pub/CPAN';

    debug { "Syncing files from '$mirror'\n" };

    my @files = qw(
        indices/find-ls.gz
        authors/00whois.xml
        modules/06perms.txt.gz
        modules/02packages.details.txt.gz
    );

    require LWP::UserAgent;
    my $ua = new LWP::UserAgent;
    $ua->timeout( 10 );

    foreach my $file ( @files ) {
        debug { "Fetching '$file'\n" };
        my $store = $self->file_path( $file );
        $self->backup_file( $store ) if -e $store;
        my $response = $ua->get( "$mirror/$file", ':content_file' => $store );
        unless ( $response->is_success ) {
            print STDERR $response->status_line, "\n";
            next;
        }
        my $mtime = $response->header('Last-Modified');

        debug { "Fetched '$file' -> '$store'\n" };

        if ( $store =~ /(.*)\.gz$/ ) {
            $self->backup_file( $1 );
            `gunzip -f $store`;
            $store =~ s/\.gz$//;
            debug { "Unzipped '$store'\n" };
        }

        if ( $mtime ) {
            require HTTP::Date;
            $mtime = HTTP::Date::str2time( $mtime );
            utime $mtime, $mtime, $store if $mtime;
            debug { "Last modified: $mtime\n" };
        }
    }
}

{ my $cache;
sub authors {
    my $self = shift;
    $cache = $self->_authors unless $cache;
    return $cache;
} }

sub _authors {
    my $self = shift;
    my $file = '00whois.xml';
    debug { "Parsing $file...\n" };
    my $path = $self->file_path( $file );

    use XML::SAX::ParserFactory;
    my $handler = CPAN2RT::UsersSAXParser->new();
    my $p = XML::SAX::ParserFactory->parser(Handler => $handler);

    open my $fh, "<:raw", $path or die "Couldn't open '$path': $!";
    my $res = $p->parse_file( $fh );
    close $fh;

    return $res;
}

{ my $cache;
sub permissions {
    my $self = shift;
    $cache = $self->_permissions unless $cache;
    return $cache;
} }

sub _permissions {
    my $self = shift;
    my $file = '06perms.txt';
    debug { "Parsing $file...\n" };
    my $path = $self->file_path( $file );
    open my $fh, "<:utf8", $path or die "Couldn't open '$path': $!";

    $self->skip_header( $fh );

    my %res;
    while ( my $str = <$fh> ) {
        chomp $str;

        my ($module, $cpanid, $permission) = (split /\s*,\s*/, $str);
        unless ( $module && $cpanid ) {
            debug { "couldn't parse '$str' from '$file'\n" };
            next;
        }
        $res{ $module } ||= [];
        push @{ $res{ $module } }, $cpanid;
    }
    close $fh;

    return \%res;
}

{ my $cache;
sub module2file {
    my $self = shift;
    $cache = $self->_module2file() unless $cache;
    return $cache;
} }

sub _module2file {
    my $self = shift;
    my $file = '02packages.details.txt';
    debug { "Parsing $file...\n" };
    my $path = $self->file_path( $file );
    open my $fh, "<:utf8", $path or die "Couldn't open '$path': $!";

    $self->skip_header( $fh );

    my %res;
    while ( my $str = <$fh> ) {
        chomp $str;

        my ($module, $mver, $file) = split /\s+/, $str;
        unless ( $module && $file ) {
            debug { "couldn't parse '$str'\n" };
            next;
        }
        $res{ $module } = $file;
    }
    close $fh;

    return \%res;
}


{ my $cache;
sub all_distributions {
    my $self = shift;
    $cache = $self->_all_distributions() unless $cache;
    return $cache;
} }

sub _all_distributions {
    my $self = shift;
    my $file = 'find-ls';
    debug { "Parsing $file...\n" };
    my $path = $self->file_path( $file );
    open my $fh, "<:utf8", $path or die "Couldn't open '$path': $!";

    my %res;
    while ( my $str = <$fh> ) {
        next if $str =~ /^\d+\s+0\s+l\s+1/; # skip symbolic links
        chomp $str;

        my ($mode, $file) = (split /\s+/, $str)[2, -1];
        next if index($mode, 'x') >= 0; # skip executables (dirs)
        # we're only interested in files in authors/id/ dir
        next unless index($file, "authors/id/") == 0;
        next unless $file =~ /\.(bz2|zip|tgz|tar\.gz)$/i;

        my $info = CPAN::DistnameInfo->new( $file );
        my $dist = $info->dist;
        unless ( $dist ) {
            debug { "Couldn't parse distribution name from '$file'\n" };
            next;
        }
        push @{ $res{ $dist }{'versions'} ||= [] }, $info->version;
        push @{ $res{ $dist }{'uploaders'} ||= [] }, $info->cpanid;
    }
    close $fh;

    return \%res;
}

sub sync_authors {
    my $self = shift;
    my $force = shift;
    if ( !$force && !$self->is_new_file( '01mailrc.txt' ) ) {
        debug { "Skip syncing, file's not changed\n" };
        return (1);
    }

    my @errors;
    my $authors = $self->authors;
    while ( my ($cpanid, $meta) = each %$authors ) {
        my ($user, @msg) = $self->load_or_create_user( $cpanid, @{ $meta }{qw(fullname email)} );
        push @errors, @msg unless $user;
    }
    return (undef, @errors) if @errors;
    return (1);
}

sub sync_distributions {
    my $self = shift;
    my $force = shift;
    if ( !$force && !$self->is_new_file( '02packages.details.txt' ) ) {
        debug { "Skip syncing, file's not changed\n" };
        return (1);
    }

    my @files = uniq values %{ $self->module2file };
    my $all_dists = $self->all_distributions;

    my %tmp;
    foreach my $file ( @files ) {
        my $info = CPAN::DistnameInfo->new( "authors/id/$file" );
        my $dist = $info->dist;
        unless ( $dist ) {
            debug { "Couldn't parse distribution name from '$file'\n" };
            next;
        }
        if ( $dist =~ /^(parrot|perl)$/i ) {
            debug { "Skipping $dist as it's hard coded to be skipped." };
            next;
        }

        $tmp{ $dist } ||= [];
        if ( my $v = $info->version ) {
            push @{ $tmp{ $dist } }, $v;
        }
        push @{ $tmp{ $dist } }, @{ $all_dists->{ $dist }{'versions'} || [] };
    }

    my @errors;
    while ( my ($dist, $versions) = each %tmp ) {
        my ($queue, @msg) = $self->load_or_create_queue( $dist );
        unless ( $queue ) {
            push @errors, @msg;
            next;
        }
        if ( $versions && @$versions ) {
            my ($status, @msg) = $self->add_versions( $queue, @$versions );
            push @errors, @msg unless $status;
        }
    }

    %tmp = ();

    return (undef, @errors) if @errors;
    return (1);
}

sub sync_maintainers {
    my $self = shift;
    my $force = shift;
    if ( !$force && !$self->is_new_file( '06perms.txt' ) ) {
        debug { "Skip syncing, file's not changed\n" };
        return (1);
    }

    my $m2f = $self->module2file;
    my $perm = $self->permissions;

    my %res;
    while ( my ($module, $maint) = each %$perm ) {
        my $file = $m2f->{ $module };
        next unless $file;

        my $dist = CPAN::DistnameInfo->new( "authors/id/$file" )->dist;
        unless ( $dist ) {
            debug { "Couldn't parse distribution name from '$file'\n" };
            next;
        }
        push @{ $res{ $dist } ||= [] }, @$maint;
    }

    my @errors = ();
    while ( my ($dist, $maint) = each %res ) {
        my ($queue, @msg) = $self->load_or_create_queue( $dist );
        unless ( $queue ) {
            push @errors, @msg;
            next;
        }

        my $status;
        ($status, @msg) = $self->set_maintainers( $queue, @$maint );
        push @errors, @msg unless $status;
    }
    %res = ();
    return (undef, @errors) if @errors;
    return (1);
}

sub current_maintainers {
    my $self = shift;
    my $queue = shift;

    my $users = $queue->AdminCc->UserMembersObj;
    $users->OrderByCols;
    return map uc $_->Name, @{ $users->ItemsArrayRef };
}

sub filter_maintainers {
    my $self = shift;
    my $authors = $self->authors;
    return grep { ($authors->{$_}{'type'}||'') eq 'author' } @_;
}

sub set_maintainers {
    my $self = shift;
    my $queue   = shift;

    my @maints  = $self->filter_maintainers( @_ );
    my @current = $self->current_maintainers( $queue );

    my @errors;

    my $set = List::Compare->new( '--unsorted', \@current, \@maints );
    foreach ( $set->get_unique ) {
        debug { "Going to delete $_ from maintainers of ". $queue->Name };
        my ($status, @msg) = $self->del_maintainer( $queue, $_, 'force' );
        push @errors, @msg unless $status;
    }
    foreach ( $set->get_complement ) {
        debug { "Going to add $_ as maintainer of ". $queue->Name };
        my ($status, @msg) = $self->add_maintainer( $queue, $_, 'force' );
        push @errors, @msg unless $status;
    }

    return (undef, @errors) if @errors;
    return (1);
}

sub add_maintainer {
    my $self = shift;
    my $queue = shift;
    my $user  = shift;
    my $force = shift || 0;

    unless ( ref $user ) {
        my $tmp = RT::User->new( $RT::SystemUser );
        $tmp->LoadByCols( Name => $user );
        return (undef, "Couldn't load user '$user'")
            unless $tmp->id;

        $user = $tmp;
    }
    unless ( $user->id ) {
        return (undef, "Empty user object");
    }

    if ( !$force && $queue->IsAdminCc( $user->PrincipalId ) ) {
        debug {  $user->Name ." is already maintainer of '". $queue->Name ."'\n"  };
        return (1);
    }

    my ($status, $msg) = $queue->AddWatcher(
        Type        => 'AdminCc',
        PrincipalId => $user->PrincipalId,
    );
    unless ( $status ) {
        $msg = "Couldn't add ". $user->Name ." as AdminCc for ". $queue->Name .": $msg\n";
        return (undef, $msg);
    } else {
        debug { "Added ". $user->Name ." as maintainer of '". $queue->Name ."'\n" };
    }
    return (1);
}

sub del_maintainer {
    my $self = shift;
    my $queue = shift;
    my $user  = shift;
    my $force = shift;

    unless ( ref $user ) {
        my $tmp = RT::User->new( $RT::SystemUser );
        $tmp->LoadByCols( Name => $user );
        return (undef, "Couldn't load user '$user'")
            unless $tmp->id;

        $user = $tmp;
    }
    unless ( $user->id ) {
        return (undef, "Empty user object");
    }

    if ( !$force && !$queue->IsAdminCc( $user->PrincipalId ) ) {
        debug {  $user->Name ." is not maintainer of '". $queue->Name ."'. Skipping...\n"  };
        return (1);
    }

    my ($status, $msg) = $queue->DeleteWatcher(
        Type        => 'AdminCc',
        PrincipalId => $user->PrincipalId,
    );
    unless ( $status ) {
        $msg = "Couldn't delete ". $user->Name
            ." from AdminCc list of '". $queue->Name ."': $msg\n";
        return (undef, $msg);
    } else {
        debug { "Deleted ". $user->Name ." from maintainers of '". $queue->Name ."'\n" };
    }
    return (1);
}

sub add_versions {
    my $self = shift;
    my ($queue, @versions) = @_;
    @versions = uniq @versions;

    my @errors;
    foreach my $name ( "Broken in", "Fixed in" ) {
        my ($cf, $msg) = $self->load_or_create_version_cf( $queue, $name );
        unless ( $cf ) {
            push @errors, $msg;
            next;
        }

        # Unless it's a new value, don't add it
        my %old = map { $_->Name => 1 } @{ $cf->Values->ItemsArrayRef };
        foreach my $version ( grep defined && length, @versions ) {
            if ( exists $old{$version} ) {
                debug { "Version '$version' exists (not adding)\n" };
                next;
            }

            my ($val, $msg) = $cf->AddValue(
                Name          => $version,
                Description   => "Version $version",
                SortOrder     => 0,
            );
            unless ( $val ) {
                $msg = "Failed to add value '$version' to CF $name"
                    ." for queue ". $queue->Name .": $msg";
                debug {  $msg  };
                push @errors, $msg;
            }
            else {
                debug { "Added version '$version' into '$name' list for queue '". $queue->Name ."'\n" };
            }
        }
    }
    return (undef, @errors) if @errors;
    return (1);
}

sub load_or_create_user {
    my $self = shift;
    my ($cpanid, $realname, $email) = @_;

    my $bycpanid = RT::User->new($RT::SystemUser);
    $bycpanid->LoadByCol( Name => $cpanid );

    # WARNING: when MergeUser extension is used then the same user records
    # will be loaded even when there are multiple records in the DB
    $email = $self->parse_email_address( $email ) || "$cpanid\@cpan.org";
    my $byemail = RT::User->new( $RT::SystemUser );
    $byemail->LoadByEmail( $email );

    if ( $bycpanid->id && (($byemail->id && $bycpanid->id == $byemail->id) || !$byemail->id) ) {
        # the same users, both cpanid and email...
        # or email change, so no user with new email...
        #
        # XXX: as we have no way to detect email changes on PAUSE
        # then we set email to the public version from PAUSE only when
        # user in RT has no email. The same applies to name.
        $bycpanid->SetEmailAddress( $email )
            unless $bycpanid->EmailAddress;
        $bycpanid->SetRealName( $realname )
            unless $bycpanid->RealName;
        return $bycpanid;
    }
    elsif ( $bycpanid->id && $byemail->id ) {
        # both exist, but different
        # XXX: merge them
        debug { "WARNING: Two different users\n" };
        return $bycpanid;
    }
    elsif ( $byemail->id ) {
        # there is already user with that address, but different CPANID
        my ($new, $msg) = $self->create_user( $cpanid, $realname );
        return ($new, $msg) unless $new;

        if ( $new->can('MergeInto') ) {
            debug { "Merging user @{[$new->Name]} into @{[$byemail->Name]}...\n" };
            $new->MergeInto( $byemail );
        } else {
            debug {
                "WARNING: Couldn't merge user @{[$new->Name]} into @{[$byemail->Name]}."
                ." Extension is not installed.\n" };
        }
        return ($new);
    }

    return $self->create_user($cpanid, $realname, $email);
}

sub create_user {
    my $self = shift;
    my ($username, $realname, $email) = @_;

    my $user = RT::User->new( $RT::SystemUser );
    my ($val, $msg) = $user->Create(
        Name          => $username,
        RealName      => $realname,
        EmailAddress  => $email,
        Privileged    => 1
    );

    unless ( $val ) {
        $msg = "Failed to create user $username: $msg";
        debug { "FAILED! $msg\n" };
        return (undef, $msg);
    }
    else {
        debug { "Created user $username... " };
    }

    return ($user)
}

sub load_or_create_queue {
    my $self = shift;
    my $dist = shift;

    my $queue = RT::Queue->new( $RT::SystemUser );
    # Try to load up the current queue by name.  Avoids duplication.
    $queue->Load( $dist );
    unless ( $queue->id ) {
        my ($status, $msg) = $queue->Create(
            Name               => $dist,
            Description        => "Bugs in $dist",
            CorrespondAddress  => "bug-$dist\@rt.cpan.org",
            CommentAddress     => "comment-$dist\@rt.cpan.org",
        );
        unless ( $status ) {
            return (undef, "Couldn't create queue '$dist': $msg\n");
        }
		debug { "Created queue #". $queue->id ." for dist ". $queue->Name ."\n" };
    } else {
		debug { "Found queue #". $queue->id ." for dist ". $queue->Name ."\n" };
    }
    return $queue;
}

sub load_or_create_version_cf {
    my $self = shift;
    my ($queue, $name) = @_;

    my $cfs = RT::CustomFields->new( $RT::SystemUser );
    $cfs->Limit( FIELD => 'Name', VALUE => $name );
    $cfs->LimitToQueue( $queue->id );
    $cfs->{'find_disabled_rows'} = 0;   # This is why we don't simply do a LoadByName
    $cfs->OrderByCols; # don't sort things
    $cfs->RowsPerPage( 1 );

    my $cf = $cfs->First;
    unless ( $cf && $cf->id ) {
        return $self->create_version_cf( $queue, $name );
    }

    return ($cf);
}

sub create_version_cf {
    my $self = shift;
    my ($queue, $name) = @_;

    my $cf = RT::CustomField->new( $RT::SystemUser );
    debug { "creating custom field $name..." };
    my ($val, $msg) = $cf->Create(
        Name            => $name,
        TypeComposite   => 'Select-0',    
        # This is a much clearer way of associating a CF
        # with a queue, except that it's not as efficient
        # as the method below...
        # 
        #Queue           => $queue->Id,
        #
        # So instead we're going to set the lookup type here...
        #
        LookupType   => 'RT::Queue-RT::Ticket',
    );
    unless ( $val ) {
        debug { "FAILED!  $msg\n" };
        return (undef, "Failed to create CF $name for queue "
                        . $queue->Name
                        . ": $msg");
    }
    else {
        debug { "ok\n" };
    }

    #
    # ... and associate with the queue down here.
    #
    # This is the other way of associating a CF with a queue.  Unlike
    # the much more clear method above, it doesn't have to fetch the
    # queue object again.  And since this is an import, we do kinda
    # care about that stuff...
    #
    ($val, $msg) = $cf->AddToObject( $queue );
    unless ( $val ) {
        $msg = "Failed to link CF $name with queue " . $queue->Name . ": $msg";
        debug { $msg };
        $cf->Delete;
        return (undef, $msg);
    }
    return ($cf);
}

sub parse_email_address {
    my $self = shift;
    my $string = shift;
    return undef unless defined $string && length $string;
    return undef if uc($string) eq 'CENSORED';

    my $address = (grep defined, Email::Address->parse( $string || '' ))[0];
    return undef unless defined $address;
    return $address->address;
}

sub file_path {
    my $self = shift;
    my $file = shift;
    my $res = $file;
    $res =~ s/.*\///; # strip leading dirs
    if ( my $dir = $self->{'datadir'} ) {
        require File::Spec;
        $res = File::Spec->catfile( $dir, $res );
    }
    return $res;
}

sub is_new_file {
    my $self = shift;
    my $new = $self->file_path( shift );
    my $old = $new .'.old';
    return 1 unless -e $old; 
    return (stat $new)[9] > (stat $old)[9]? 1 : 0;
}

sub backup_file {
    my $self = shift;
    my $old = shift;
    my $new = $old .'.old';
    rename $old, $new;
}

sub skip_header {
    my $self = shift;
    my $fh = shift;
    while ( my $str = <$fh> ) {
        return if $str =~ /^\s*$/;
    }
}

sub debug(&) {
    return unless $DEBUG;
    print STDERR map { /\n$/? $_ : $_."\n" } $_[0]->();
}

1;

package CPAN2RT::UsersSAXParser;
use base qw(XML::SAX::Base);

sub start_document {
    my ($self, $doc) = @_;
    $self->{'res'} = {};
}

sub start_element {
    my ($self, $el) = @_;
    my $name = $el->{LocalName};
    return if $name ne 'cpanid' && !$self->{inside};

    if ( $name eq 'cpanid' ) {
        $self->{inside} = 1;
        $self->{tmp} = [];
        return;
    } else {
        $self->{inside_prop} = 1;
    }

    push @{ $self->{'tmp'} }, $name, '';
}

sub characters {
    my ($self, $el) = @_;
    $self->{'tmp'}[-1] .= $el->{Data} if $self->{inside_prop};
}

sub end_element {
    my ($self, $el) = @_;
    $self->{inside_prop} = 0;

    my $name = $el->{LocalName};

    if ( $name eq 'cpanid' ) {
        $self->{inside} = 0;
        my %rec = map Encode::decode_utf8($_), @{ delete $self->{'tmp'} };
        $self->{'res'}{ delete $rec{'id'} } = \%rec;
    }
}

sub end_document {
    my ($self) = @_;
    return $self->{'res'};
}

1;
