package Biblio::Zotero::DB::Schema::ResultSet::ItemData;
$Biblio::Zotero::DB::Schema::ResultSet::ItemData::VERSION = '0.004';
use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

sub fields_for_itemid {
	my ($self, $itemid) = @_;


	return { map { $_->field_value }
		$self->search(
			{ 'itemid' => $itemid },
			{ prefetch => [qw/fieldid valueid/] }
		)->all
	};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Biblio::Zotero::DB::Schema::ResultSet::ItemData

=head1 VERSION

version 0.004

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
