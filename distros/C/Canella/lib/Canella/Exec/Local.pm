package Canella::Exec::Local;
use Moo;
use IPC::Run ();
use Canella::Log;

has stdout      => ( is => 'rw' );
has stderr      => ( is => 'rw' );
has has_error   => ( is => 'rw' );
has error       => ( is => 'rw' );
has cmd => (
    is => 'ro',
    isa => sub { ref $_[0] eq 'ARRAY' },
    required => 1,
);

sub execute {
    my $self = shift;

    infof "[localhost :: executing] %s", join ' ', @{$self->cmd};
    my $result = IPC::Run::run($self->cmd, \my $stdin, \my $stdout, \my $stderr);
    $self->has_error(! $result);
    $self->error($?);

    chomp $stdout;
    chomp $stderr;
    $self->stdout($stdout);
    $self->stderr($stderr);

    foreach my $name (qw(stdout stderr)) {
        foreach my $line ( split /\n/, $self->$name ) {
            infof "[localhost :: %s] %s", $name, $line;
        }
    }
}

1;
    
