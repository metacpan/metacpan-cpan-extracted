package DBIx::Class::InflateColumn::Markup::Unified;

use warnings;
use strict;
use base qw/DBIx::Class/;
use Markup::Unified;

=head1 NAME

DBIx::Class::InflateColumn::Markup::Unified - Automatically formats a text column
with Textile, Markdown or BBCode.

=head1 VERSION

Version 0.021

=cut

our $VERSION = '0.021';

=head1 SYNOPSIS

Load this component and declare that text columns use a markup language.
You can either "hard code" the markup language into the column, or grab it
from another column in the row (must be 'markup_lang' right now). This is
useful if each row might use a different markup langauge. Supported languages
are L<Textile|Text::Textile>, L<Markdown|Text::Markdown> and L<BBCode|HTML::BBCode>.

    package Posts;
    __PACKAGE__->load_components(qw/InflateColumn::Markup Core/);
    __PACKAGE__->add_columns(
        text => {
            data_type => 'TEXT',
            is_nullable => 0,
            is_markup => 1,
            markup_lang => 'textile',
        }
    );

    # or, alternatively
    __PACKAGE__->add_columns(
        text => {
            data_type => 'TEXT',
            is_nullable => 0,
            is_markup => 1,
        },
        markup_lang => {
            data_type => 'VARCHAR',
            is_nullable => 0,
            size => 60,
        },
    );

Then, printing the column will automatically use the markup language:

    print $row->text; # automatically formats according to the markup language

    # you can also use
    print $row->text->formatted; # again, automatically formats
    print $row->text->unformatted; # prints the text as-is, unformatted

=head1 METHODS

=head2 register_column

Chains with L<DBIx::Class::Row/register_column>, and formats columns
appropriately. This would not normally be called directly by end users.

=cut

__PACKAGE__->load_components(qw/InflateColumn/);

sub register_column {
	my ($self, $column, $info, @rest) = @_;
	$self->next::method($column, $info, @rest);

	return unless defined $info->{is_markup};

	my $markup_lang = $info->{markup_lang};

	$self->inflate_column(
		$column => {
			inflate => sub {
				my ($value, $row) = @_;

				$markup_lang ||= $row->markup_lang;
				return Markup::Unified->new->format($value, $markup_lang);
			},
			deflate => sub { return shift->unformatted; },
		}
	);
}

=head1 AUTHOR

Ido Perlmuter, C<< <ido at fc-bnei-yehuda.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dbix-class-inflatecolumn-markup-unified at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=DBIx-Class-InflateColumn-Markup-Unified>. I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc DBIx::Class::InflateColumn::Markup::Unified

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=DBIx-Class-InflateColumn-Markup-Unified>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/DBIx-Class-InflateColumn-Markup-Unified>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/DBIx-Class-InflateColumn-Markup-Unified>

=item * Search CPAN

L<http://search.cpan.org/dist/DBIx-Class-InflateColumn-Markup-Unified/>

=back

=head1 SEE ALSO

L<DBIx::Class>, L<DBIx::Class::InflateColumn>, L<Markup::Unified>

=head1 COPYRIGHT & LICENSE

Copyright 2009 Ido Perlmuter.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of DBIx::Class::InflateColumn::Markup::Unified
