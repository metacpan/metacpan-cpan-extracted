package Aion::Format::Json;

use common::sense;
use JSON::XS qw//;

use Exporter qw/import/;
our @EXPORT = our @EXPORT_OK = grep {
    *{$Aion::Format::Json::{$_}}{CODE} && !/^(_|(NaN|import)\z)/n
} keys %Aion::Format::Json::;

#@category json

# Настраиваем json
our $JSON = JSON::XS->new->allow_nonref->indent(1)->space_after(1)->canonical(1);

# В json
sub to_json(;$) {
	$JSON->encode(@_ == 0? $_: @_)
}

# Из json
sub from_json(;$) {
	$JSON->decode(@_ == 0? $_: @_)
}

1;

__END__

=encoding utf-8

=head1 NAME

Aion::Format::Json - Perl extension for formatting JSON

=head1 SYNOPSIS

	use Aion::Format::Json;
	
	to_json {a => 10}    # => {\n   "a": 10\n}\n
	from_json '[1, "5"]' # --> [1, "5"]

=head1 DESCRIPTION

C<Aion::Format::Json> based on C<JSON::XS>. And includethe following settings:

=over

=item * allow_nonref - coding and decoding scalars.

=item * indent - enable multiline with indent on begin lines.

=item * space_after - C<\n> after json.

=item * canonical - sorting keys in hashes.

=back

=head1 SUBROUTINES

=head2 to_json (;$data)

Translate data to json format.

	my $data = {
	    a => 10,
	};
	
	my $result = '{
	   "a": 10
	}
	';
	
	to_json $data # -> $result
	
	local $_ = $data;
	to_json # -> $result

=head2 from_json (;$string)

Parse string in json format to perl structure.

	from_json '{"a": 10}' # --> {a => 10}
	
	[map from_json, "{}", "2"]  # --> [{}, 2]

=head1 AUTHOR

Yaroslav O. Kosmina LL<mailto:darviarush@mail.ru>

=head1 LICENSE

⚖ B<GPLv3>

=head1 COPYRIGHT

The Aion::Format::Json module is copyright © 2023 Yaroslav O. Kosmina. Rusland. All rights reserved.
