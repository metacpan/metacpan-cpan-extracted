package Data::Collector::Engine::OpenSSH;
{
  $Data::Collector::Engine::OpenSSH::VERSION = '0.15';
}
# ABSTRACT: An OpenSSH engine for Data::Collector utilizing Net::OpenSSH

use Moose;
use Net::OpenSSH;
use namespace::autoclean;

extends 'Data::Collector::Engine';

has '+name'  => ( default => 'OpenSSH' );

has 'host'   => (
    is        => 'rw',
    isa       => 'Str',
    predicate => 'has_host',
    required  => 1,
);

has 'user'   => ( is => 'rw', isa => 'Str', predicate => 'has_user'   );
has 'passwd' => ( is => 'rw', isa => 'Str', predicate => 'has_passwd' );
has 'port'   => ( is => 'rw', isa => 'Int', predicate => 'has_port' );
has 'ssh'    => (
    is         => 'ro',
    isa        => 'Net::OpenSSH',
    lazy_build => 1,
);

sub _build_ssh {
    my $self = shift;

    return $self->connect();
}

sub connect {
    my $self = shift;
    my %data = ();
    foreach my $attr ( qw/ user passwd port / ) {
        my $predicate = "has_$attr";
        $self->$predicate and $data{$attr} = $self->$attr;
    }

    my $ssh = Net::OpenSSH->new( $self->host, %data );

    $ssh->error and die "OpenSSH Engine connect failed: " . $ssh->error;
    return $ssh;
}

sub run {
    my ( $self, $cmd ) = @_;

    return $self->ssh->capture($cmd);
}

sub pipe {
    my ( $self, $cmd, $params ) = @_;
    my ( $in, $out, $pid ) = $self->ssh->open2($cmd);

    print {$in} $params;
    close $in;

    my $output;
    while ( <$out> ) { $output .= $_; }
    close $out;

    return $output;
}

__PACKAGE__->meta->make_immutable;
1;



=pod

=head1 NAME

Data::Collector::Engine::OpenSSH - An OpenSSH engine for Data::Collector utilizing Net::OpenSSH

=head1 VERSION

version 0.15

=head1 SYNOPSIS

    use Data::Collector;

    my $collector = Data::Collector->new(
        engine      => 'OpenSSH', # the default
        engine_args => {
            user   => 'me',
            host   => 'soymilkyway',
            passwd => 'crow@MIDn1ght',
        },
    );

=head1 ATTRIBUTES

=head2 host(Str)

Host to connect to. B<Required>.

=head2 user(Str)

Username to connect with. Defaults to session user.

=head2 passwd(Str)

Password to be used in connection. As with the OpenSSH C<ssh> program, if a
password is ot provided, it will go over other methods (such as keys), so this
is not required.

=head2 ssh(Object)

Contains the L<Net::OpenSSH> object that is used.

=head1 SUBROUTINES/METHODS

=head2 connect

This method creates the Net::OpenSSH object and connects to the host.

=head2 run

This functions runs the given command on the host using ssh and returns the
results.

=head2 pipe

Pipes your request to the command. Gets the command to run, returns the output
of that command.

=head1 AUTHOR

Sawyer X <xsawyerx@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Sawyer X.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

