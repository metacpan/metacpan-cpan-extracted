package t::Object::HookedTT;

use Class::InsideOut ':std';
use Types::Standard -types;

# $_ has the first argument in it for convenience
public integer => my %integer, { set_hook => Int };

# first argument is also available directly
public word => my %word, { set_hook => StrMatch[qr/\A\w+\z/] };

# Changing $_ changes what gets stored
my $UC = (StrMatch[qr/\A[A-Z]+\z/])->plus_coercions(Str, q{uc $_});
public uppercase => my %uppercase, {
    set_hook => sub {
       $_ = $UC->coercion->($_)
    },
};

# Full @_ is available, but only first gets stored
public list => my %list, {
    set_hook => sub { $_ = ArrayRef->check($_) ? $_ : [ @_ ] },
    get_hook => sub { @$_ },
};

public reverser => my %reverser, {
    set_hook => sub { $_ = ArrayRef->check($_) ? $_ : [ @_ ] },
    get_hook => sub {  reverse @$_ }
};

public write_only => my %only_only, {
    get_hook => sub { die "is write-only\n" }
};
    
sub new {
    register( bless {}, shift );
}

1;
