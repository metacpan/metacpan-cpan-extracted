package t::Object::HookedOverloaded;

sub mysub (&) {
    package t::Object::HookedOverloaded::mysub;
    use overload q[&{}] => sub { shift->{code} }, fallback => 1;
    bless { code => $_[0] };
}

use Class::InsideOut ':std';

# $_ has the first argument in it for convenience
public integer => my %integer, { 
    set_hook => mysub { /\A\d+\z/ or die "must be an integer\n" }, 
};

# first argument is also available directly
public word => my %word, {
    set_hook => mysub { $_[0] =~ /\A\w+\z/ or die "must be a Perl word\n" },
};

# Changing $_ changes what gets stored
public uppercase => my %uppercase, {
    set_hook => mysub { $_[0] = uc },
};

# Full @_ is available, but only first gets stored
public list => my %list, {
    set_hook => mysub { $_ = ref $_ eq 'ARRAY' ? $_ : [ @_ ] },
    get_hook => mysub { @$_ },
};

public reverser => my %reverser, {
    set_hook => mysub { $_ = (ref $_ eq 'ARRAY') ? $_ : [ @_ ] },
    get_hook => mysub {  reverse @$_ }
};

public write_only => my %only_only, {
    get_hook => mysub { die "is write-only\n" }
};
    
sub new {
    register( bless {}, shift );
}

1;
