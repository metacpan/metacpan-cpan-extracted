package App::DB::Schema::Declare;
use Dwarf::Pragma;
use Teng::Schema::Declare;
use DateTime::Format::Pg;

use Exporter::Lite;
our @EXPORT = qw(datetime_columns);

sub datetime_columns {
	my $columns_regexp = join('|', @_);
	my $regexp = qr{^(?:$columns_regexp)$};
	my ($pkg) = caller;
	my $inflate = \&{$pkg . '::inflate'};
	my $deflate = \&{$pkg . '::deflate'};
	$inflate->($regexp => sub { DateTime::Format::Pg->parse_datetime(@_) });
	$deflate->($regexp => sub { DateTime::Format::Pg->format_datetime(@_) });
}

1;
