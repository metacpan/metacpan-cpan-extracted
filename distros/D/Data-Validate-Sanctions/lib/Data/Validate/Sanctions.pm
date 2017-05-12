package Data::Validate::Sanctions;

use strict;
use warnings;

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw/is_sanctioned set_sanction_file get_sanction_file/;

use Carp;
use File::stat;
use Scalar::Util qw(blessed);

our $VERSION = '0.10';

# for OO
sub new {    ## no critic (RequireArgUnpacking)
    my $class = shift;
    my %args  = @_;
    my $self  = {};
    $self->{sanction_file} = $args{sanction_file} // _default_sanction_file();
    $self->{last_time} = 0;
    return bless $self, ref($class) || $class;
}

my $sanction_file = _default_sanction_file();
my $instance;

sub set_sanction_file {    ## no critic (RequireArgUnpacking)
    $sanction_file = shift // die "sanction_file is needed";
    undef $instance;
    return;
}

sub get_sanction_file {
    return $instance ? $instance->{sanction_file} : $sanction_file;
}

sub is_sanctioned {        ## no critic (RequireArgUnpacking)
    my $self = blessed($_[0]) ? shift : $instance;

    unless ($self) {
        $instance = __PACKAGE__->new(sanction_file => $sanction_file);
        $self = $instance;
    }

    my $name = join('', @_);
    $name = uc($name);
    $name =~ s/[[:^alpha:]]//g;

    my $data = $self->_load_data();
    return 1 if grep { $_ eq $name } @$data;

    # try reverse
    if (@_ > 1) {
        $name = join('', reverse @_);
        $name = uc($name);
        $name =~ s/[[:^alpha:]]//g;
        return 1 if grep { $_ eq $name } @$data;
    }

    return 0;
}

sub _load_data {
    my $self          = shift;
    my $sanction_file = $self->{sanction_file};
    my $stat          = stat($sanction_file) or croak "Can't get stat of file $sanction_file, please check it.\n";
    return $self->{_data} if ($stat->mtime <= $self->{last_time} && $self->{_data});

    open(my $fh, '<', $sanction_file) or croak "Can't open file $sanction_file, please check it.\n";
    my @_data = <$fh>;
    close($fh);
    chomp(@_data);
    $self->{last_time} = $stat->mtime;
    $self->{_data}     = \@_data;
    return $self->{_data};
}

sub _default_sanction_file {
    return $ENV{SANCTION_FILE} if $ENV{SANCTION_FILE};
    my $sanction_file = __FILE__;
    $sanction_file =~ s/\.pm/\.csv/;
    return $sanction_file;
}

1;
__END__

=encoding utf-8

=head1 NAME

Data::Validate::Sanctions - Validate a name against sanctions lists

=head1 SYNOPSIS

    # as exported function
    use Data::Validate::Sanctions qw/is_sanctioned get_sanction_file set_sanction_file/;
    set_sanction_file('/var/storage/sanction.csv');

    my ($first_name, $last_name) = ("First", "Last Name");
    print 'BAD' if is_sanctioned($first_name, $last_name);

    # as OO
    use Data::Validate::Sanctions;

    #You can also set sanction_file in the new method.
    my $validator = Data::Validate::Sanctions->new(sanction_file => '/var/storage/sanction.csv');
    print 'BAD' if $validator->is_sanctioned("$last_name $first_name");

=head1 DESCRIPTION

Data::Validate::Sanctions is a simple validitor to validate a name against sanctions lists.

The list is from L<https://www.treasury.gov/ofac/downloads/sdn.csv>, L<https://www.treasury.gov/ofac/downloads/consolidated/cons_prim.csv>

run F<update_sanctions_csv> to update the bundled csv.

The path of list can be set by function L</set_sanction_file> or by method L</new>. If not set, then environment variable $ENV{SANCTION_FILE} will be checked, at last
the default file in this package will be used.

=head1 METHODS

=head2 is_sanctioned

    is_sanctioned($last_name, $first_name);
    is_sanctioned($first_name, $last_name);
    is_sanctioned("$last_name $first_name");

when one string is passed, please be sure last_name is before first_name.

or you can pass first_name, last_name (last_name, first_name), we'll check both "$last_name $first_name" and "$first_name $last_name".

return 1 for yes, 0 for no.

it will remove all non-alpha chars and compare with the list we have.

=head2 new

Create the object, and set sanction_file

    my $validator = Data::Validate::Sanctions->new(sanction_file => '/var/storage/sanction.csv');

=head2 get_sanction_file

get sanction_file which is used by L</is_sanctioned> (procedure-oriented)

=head2 set_sanction_file

set sanction_file which is used by L</is_sanctioned> (procedure-oriented)

=head1 AUTHOR

Binary.com E<lt>fayland@binary.comE<gt>

=head1 COPYRIGHT

Copyright 2014- Binary.com

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Data::OFAC>

=cut
