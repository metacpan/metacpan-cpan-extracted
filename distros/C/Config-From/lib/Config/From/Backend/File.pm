package Config::From::Backend::File;
$Config::From::Backend::File::VERSION = '0.05';

use utf8;
use Moose;
extends 'Config::From::Backend';

use Config::Any;
use Carp qw/croak/;

has file => (
    is       => 'rw',
    required => 1,
    isa      => 'Str',
);


has datas => (
    is         => 'rw',
    isa        => 'HashRef',
    lazy_build => 1,
    builder => '_build_datas',
);

sub _build_datas {
    my $self = shift;

    my $file = $self->file;
    my $cfg = Config::Any->load_files({files => [$file], use_ext => 1 });
    croak "Can not open $file !" if ! $cfg->[0];
    my ($filename, $config) = %{$cfg->[0]};
    return $config;
}

=head1 NAME

Config::From::Backend::File -  File Backend for Config::From


=head1 VERSION

version 0.05

=head1 SYNOPSIS

    my $bckfile = Config::From::Backend::File->new(file => 't/conf/file1.yml');

    my $config = $bckfile->datas

=head1 SUBROUTINES/METHODS

=head2 file

  The file to load from diffrents file format. It use Config::Any

=head2 datas

  The data returned by the backend

=head1 SEE ALSO

L<Config::Any>

=head1 AUTHOR

Daniel Brosseau, C<< <dab at catapulse.org> >>

=cut

1; # End of Config::From::Backend::File
