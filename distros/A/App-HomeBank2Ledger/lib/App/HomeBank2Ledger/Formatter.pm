package App::HomeBank2Ledger::Formatter;
# ABSTRACT: Abstract class for formatting a ledger


use warnings;
use strict;

use Module::Load;
use Module::Pluggable search_path   => [__PACKAGE__],
                      sub_name      => 'available_formatters';

our $VERSION = '0.003'; # VERSION

sub _croak { require Carp; Carp::croak(@_) }


sub new {
    my $class = shift;
    my %args  = @_;

    my $package = __PACKAGE__;

    if ($class eq $package and my $type = $args{type}) {
        # factory
        for my $formatter ($class->available_formatters) {
            next if lc($formatter) ne lc("${package}::${type}");
            $class = $formatter;
            load $class;
            last;
        }
        _croak('Invalid formatter type') if $class eq $package;
    }

    return bless {%args}, $class;
}


sub format {
    ...
}


sub type            { shift->{type} }
sub name            { shift->{name} }
sub file            { shift->{file} }
sub account_width   { shift->{account_width} || 40 }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::HomeBank2Ledger::Formatter - Abstract class for formatting a ledger

=head1 VERSION

version 0.003

=head1 SYNOPSIS

    my $formatter = App::HomeBank2Ledger::Formatter->new(
        type    => 'ledger',
    );
    print $formatter->format($ledger);

=head1 DESCRIPTION

This class formats L<ledger data|App::HomeBank2Ledger::Ledger> as for a file.

=head1 ATTRIBUTES

=head2 type

Get the type of formatter.

=head2 name

Get the name or title of the ledger.

=head2 file

Get the filepath where the ledger data came from.

=head2 account_width

Get the number of characters to use for the account column.

=head1 METHODS

=head2 new

    $formatter = App::HomeBank2Ledger::Formatter->new(type => $format);

Construct a new formatter object.

=head2 format

    $str = $formatter->format($ledger);

Do the actual formatting of ledger data into a serialized form.

This must be overridden by subclasses.

=head1 SEE ALSO

=over 4

=item *

L<App::HomeBank2Ledger::Formatter::Beancount>

=item *

L<App::HomeBank2Ledger::Formatter::Ledger>

=back

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/chazmcgarvey/homebank2ledger/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Charles McGarvey <chazmcgarvey@brokenzipper.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Charles McGarvey.

This is free software, licensed under:

  The MIT (X11) License

=cut
