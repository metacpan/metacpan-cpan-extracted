package App::Glacier::Job::FileRetrieval;
use strict;
use warnings;

require App::Glacier::Job::ArchiveRetrieval;
use parent qw(App::Glacier::Job::ArchiveRetrieval);
use App::Glacier::Core;
use Carp;

# new(CMD, VAULT, FILE[, VERSION])
sub new {
    croak "bad number of arguments" if $#_ < 3 || $#_ > 4;
    my ($class, $cmd, $vault, $file, $version) = @_;

    my $dir = $cmd->directory($vault);
    unless ($dir) {
	$cmd->abend(EX_TEMPFAIL,
		    "nothing is known about vault $vault; please get directory listing first");
    }
    my $archive;
    ($archive, $version) = $dir->locate($file, $version);
    unless ($archive) {
	$version = 1 unless defined $version;
	$cmd->abend(EX_NOINPUT,
		    "$vault:$file;$version not found; make sure directory listing is up-to-date");
    }
    
    my $self = $class->SUPER::new($cmd, $vault, $archive->{ArchiveId},
				  description => "Retrieval of $file;$version",
				  ttl => $cmd->cfget(qw(database job ttl)));
    $self->{_filename} = $file;
    $self->{_fileversion} = $version;
    return $self;
}

sub file_name {
    my ($self, $full) = @_;
    if ($full) {
	return $self->{_filename} . ';' . $self->{_fileversion};
    } else {
	return $self->{_filename};
    }
}

sub file_version {
    my ($self) = @_;
    return $self->{_fileversion};
}

1;
