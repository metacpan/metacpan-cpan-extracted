package Data::Dumper::Store;

use strict;
use warnings;
use 5.010;

use Data::Dumper;

$Data::Dumper::Purity = 1;
$Data::Dumper::Terse = 1;

=head1 NAME

    Data::Dumper::Store - persistent key-value storage engine based on Data::Dumper serialization mechanism and flat files.

=head1 VERSION

    Version 1.01

=cut

our $VERSION = '1.01';

sub new {
    my ($class, %opts) = @_;

    defined $opts{file} or die "File is not specified";

    my $self = {
        file => $opts{file},
        data => {},
    };
    _init($self);

    return bless $self, $class;
}

sub _init {
    my ($self) = @_;

    return unless -e $self->{file};
    open my $fh, '<', $self->{file}
        or return;
    my $text = do { local $/; <$fh> };
    my $data = eval($text);

    return if $@;

    $self->{data} = $data;
}

sub init {
    my ($self, $data) = @_;

    defined $data && ref $data && ref $data eq 'HASH' or return;
    $self->{data} = $data;

    return $self;
}

sub set {
    my ($self, $key, $val) = @_;

    $self->{data}{$key} = $val;

    return $self;
}

sub get {
    my ($self, $key) = @_;

    return unless $key;

    return $self->{data}{$key};
}

sub dump {
    my ($self) = @_;

    return Dumper $self->{data};
}

sub commit {
    my ($self) = @_;

    open my $fh, ">", $self->{file} or return;

    print {$fh} Dumper $self->{data};
    close $fh;

    return 1;
}

sub DESTROY {
    my ($self) = @_;

    $self->commit();
}

1;

__END__

=head1 NAME

    Data::Dumper::Store

=head1 VERSION

    Version 1.00

=head1 SYNOPSIS

    my $store = Data::Dumper::Store->new(file => 'filename.txt');
    my $data = {
        foo => 'bar'
    };

    $store->init($data);
    # or
    $store->set('foo', 'bar');

    say $store->get('foo'); # prints "bar"
    # or
    say $store->set('foo', 'bar')->get('foo'); # prints "bar" too

    say $store->dump(); # == Dumper $store->{data};

    # save data to the file:
    $store->commit();

    # or
    $store->DESTROY;

=head1 DESCRIPTION

    Data::Dumper::Store creates a dump of your data and saves it in file to
    easy access to the data.

=head1 METHODS

=head2 new

    my $store = Data::Dumper::Store->new(file => 'filename');

    Creates class instance and loads data from file to the memory.

=head2 init

    $store->init({ foo => 'bar' });

    Init your data. Use this method to create a NEW data and save it to the file.

=head2 set

    $store->set('foo', 'bar');

    Add a new data.

=head2 get

    $store->get('foo');

    Get value of the key.

=head2 commit

    $store->commit();

    Save data to the file.

=head2 dump

    $store->dump();

    Returns Dumper $store->{data}

=head1 SEE ALSO

    Data::Dumper

=head1 AUTHOR

    shootnix, C<< <shootnix at cpan.org> >>

=head1 BUGS

    Please report any bugs or feature requests to C<shootnix@cpan.org>, or through
    the github: https://github.com/shootnix/data-dumper-store

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Data::Dumper::Store


=head1 LICENSE AND COPYRIGHT

Copyright 2014 shootnix.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut
