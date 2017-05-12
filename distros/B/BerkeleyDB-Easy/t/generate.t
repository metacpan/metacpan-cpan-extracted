use strict;
use warnings;

use Test::More;

use BerkeleyDB::Easy::Common;
use BerkeleyDB::Easy::Handle;

# Unclutter generated code for human consumption
sub tidy {
	my $code = shift;
	$code =~ s/^#.+\n//mg;        # remove line directives
	$code =~ s/(?<![{};])\n//mg;  # remove excess line breaks
	$code =~ s/= +/= /mg;         # remove excess spaces
	return $code;
}

# Generated code for BerkeleyDB::Easy::Handle::get()
my $put_code = <<'HERE';
sub put {
    my @err;
    local ($!, $^E);
    local $SIG{__DIE__} = sub { @err = (BDB_FATAL, $_) };
    local $SIG{__WARN__} = sub { @err = (BDB_WARN, $_) };
    undef $BerkeleyDB::Error;
    my ($self, $key, $value, $flags) = @_;
    my $status = BerkeleyDB::Common::db_put($self, $key, $value, $flags);
    $self->_log(@err) if @err;
    if ($status) {
        $self->_throw($status);
        return();
    }
    return($value);
}
HERE

# Generated code for BerkeleyDB::Easy::Handle::exists()
#   when $BerkeleyDB::db_version < 4.6
my $exists_code = <<'HERE';
sub exists {
    undef $BerkeleyDB::Error;
    my ($self, $key, $flags) = @_;
    my ($value);
    my $status = BerkeleyDB::Common::db_get($self, $key, $value, $flags);
    if ($status) {
        $self->_throw($status, undef, 1);
        return('');
    }
    return(1);
}
HERE

my %spec = (
	put    => ['db_put',[K,V,F],[K,V,F],[V],[ ],0],
	exists => ['db_get',[K,F  ],[K,V,F],[T],[N],1],
);

my %code = (
	put    => $put_code,
	exists => $exists_code,
);

plan tests => scalar keys %spec;

while (my ($name, $spec) = each %spec) {
	my $code = $code{$name};
	my $gen = tidy(BerkeleyDB::Easy::Common->_generate
		($spec, $name, 'BerkeleyDB::Easy::Handle'));
	is $gen, $code, $name;
}

done_testing;
