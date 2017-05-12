package Brackup::Target::CloudFiles;

use strict;
use warnings;
use base 'Brackup::Target';
use Date::Parse;
use Carp qw(croak);


eval { require Net::Mosso::CloudFiles } or die "You need the Net::Mosso::CloudFiles module installed to use the CloudFiles target in brackup.  Please install this module first.\n\n";

# fields in object:
#   cf  -- Net::Mosso::CloudFiles
#   username
#   apiKey
#   chunkContainer : $self->{username} . "-chunks";
#   backupContainer : $self->{username} . "-backups";
#

sub new {
    my ($class, $confsec) = @_;
    my $self = $class->SUPER::new($confsec);
    
    $self->{username} = $confsec->value("cf_username")
        or die "No 'cf_username'";
    $self->{apiKey} = $confsec->value("cf_api_key")
        or die "No 'cf_api_key'";

	$self->_common_cf_init;

    return $self;
}

sub _common_cf_init {
    my $self = shift;
    $self->{chunkContainerName}  = $self->{username} . "-chunks";
    $self->{backupContainerName} = $self->{username} . "-backups";

    $self->{cf} = Net::Mosso::CloudFiles->new(
		user => $self->{username}, 
		key => $self->{apiKey}
	);

	#createContainer makes the object and returns it, or returns it
	#if it already exists
	$self->{chunkContainer} = 
		$self->{cf}->create_container(name => $self->{chunkContainerName})
			or die "Failed to get chunk container";
	$self->{backupContainer} =
		$self->{cf}->create_container(name => $self->{backupContainerName})
			or die "Failed to get backup container";

}

sub _prompt {
    my ($q) = @_;
    my $ans = <STDIN>;
    $ans =~ s/^\s+//;
    $ans =~ s/\s+$//;
    return $ans;
}

sub new_from_backup_header {
    my ($class, $header, $confsec) = @_;

    my $username  = ($ENV{'CF_USERNAME'} || 
        $confsec->value('cf_username') ||
		_prompt("Your CloudFiles username: "))
        or die "Need your Cloud Files username.\n";

    my $apiKey = ($ENV{'CF_API_KEY'} || 
        $confsec->value('cf_api_key') ||
		_prompt("Your CloudFiles api key: "))
        or die "Need your CloudFiles api key.\n";

    my $self = bless {}, $class;
    $self->{username} = $username;
    $self->{apiKey} = $apiKey;
    $self->_common_cf_init;
    return $self;
}

sub has_chunk {
    my ($self, $chunk) = @_;
    my $dig = $chunk->backup_digest;   # "sha1:sdfsdf" format scalar

    my $res = $self->{chunkContainer}->object(name => $dig);

    return 0 unless $res;

	#return 0 if $@ && $@ =~ /key not found/;

	#TODO: check for content type?
	#return 0 unless $res->{content_type} eq "x-danga/brackup-chunk";
    return 1;
}

sub load_chunk {
    my ($self, $dig) = @_;

    my $val = $self->{chunkContainer}->object(name => $dig)->get
        or return 0;
    return \ $val;
}

sub store_chunk {
    my ($self, $chunk) = @_;
    my $dig = $chunk->backup_digest;
    my $chunkref = $chunk->chunkref;

    my $content = do { local $/; <$chunkref> };

	$self->{chunkContainer}->object(
        name => $dig,
        content_type => 'x-danga/brackup-chunk'
    )->put($content);

	return 1;
}

sub delete_chunk {
    my ($self, $dig) = @_;

	return $self->{chunkContainer}->object(name => $dig)->delete;
}

sub chunks {
    my $self = shift;
	my @objectNames;

	my @objects = $self->{chunkContainer}->objects->all;
	foreach (@objects){ push @objectNames, $_->name;}
	return @objectNames;
}

sub store_backup_meta {
    my ($self, $name, $fh) = @_;

    my $content = do { local $/; <$fh> };

    $self->{backupContainer}->object(name => $name)->put($content);

	return 1;
}

sub backups {
    my $self = shift;

    my @ret;
	
	my @backups = $self->{backupContainer}->objects->all;

    foreach my $backup (@backups) {
        push @ret, Brackup::TargetBackupStatInfo->new(
			$self, $backup->name,
			time => str2time($backup->last_modified),
			size => $backup->size);
    }
    return @ret;
}

sub get_backup {
    my $self = shift;
    my ($name, $output_file) = @_;
	
	my $val = $self->{backupContainer}->object(name => $name)->get
		or return 0;

	$output_file ||= "$name.brackup";
    open(my $out, ">$output_file") or die "Failed to open $output_file: $!\n";

    my $outv = syswrite($out, $val);

    die "download/write error" unless 
		$outv == do { use bytes; length $val };
    close $out;

    return 1;
}

sub delete_backup {
    my $self = shift;
    my $name = shift;
    return $self->{backupContainer}->object(name => $name)->delete;
}


#############################################################
# These functions are for the brackup-verify-inventory script
#############################################################

sub chunkpath {
    my $self = shift;
    my $dig = shift;

    return $dig;
}

sub size {
    my $self = shift;
    my $dig = shift;

    my $obj = $self->{chunkContainer}->object(name => $dig);
    $obj->head();
    my $size = $obj->size;

    return $size;
}


1;

=head1 NAME

Brackup::Target::CloudFiles - backup to Rackspace's CloudFiles Service

=head1 EXAMPLE

In your ~/.brackup.conf file:

  [TARGET:cloudfiles]
  type = CloudFiles
  cf_username  = ...
  cf_api_key =  ....

=head1 CONFIG OPTIONS

=over

=item B<type>

Must be "B<CloudFiles>".

=item B<cf_username>

Your Rackspace/Mosso CloudFiles user name.

=item B<cf_api_key>

Your Rackspace/Mosso CloudFiles api key.

=back

=head1 SEE ALSO

L<Brackup::Target>

L<Net::Mosso::CloudFiles> -- required module to use Brackup::Target::CloudFiles

=head1 AUTHOR

William Wolf E<lt>throughnothing@gmail.comE<gt>


