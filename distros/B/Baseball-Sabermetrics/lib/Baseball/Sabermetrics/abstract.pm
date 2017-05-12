package Baseball::Sabermetrics::abstract;
use strict;

our $AUTOLOAD;
our %formula;

#my $DEBUG = 0;

BEGIN {
    # formulas are weird, can we improve it ?
    %formula = (
	pa  =>		sub { $_->ab + $_->bb + $_->hbp + $_->sf },
	ta  =>		sub { $_->h + $_->{'2b'} + $_->{'3b'} * 2 + $_->hr * 3 },
	ba  =>		sub { $_->h / $_->ab },
	obp =>		sub { ($_->h + $_->bb + $_->hbp) / $_->pa },
	slg =>		sub { $_->tb / $_->ab },
	ops =>		sub { $_->obp + $_->slg },
	k_9 =>		sub { $_->p_so / $_->ip * 9 },
	bb_9 =>		sub { $_->p_bb / $_->ip * 9 },
	k_bb =>		sub { $_->p_so / $_->p_bb },
	isop =>		sub { $_->slg - $_->ba },
	isod =>		sub { $_->obp - $_->ba },
	rc =>		sub { $_->ab * $_->obp },

	era =>		sub { $_->er / $_->ip * 9 },
	whip =>		sub { ($_->p_bb + $_->h_allowed) / $_->ip },
	babip =>	sub { ($_->h_allowed - $_->hr_allowed) / ($_->p_pa - $_->h_allowed - $_->p_so - $_->p_bb - $_->hr_allowed) },
	g_f =>		sub { $_->go / $_->ao },

#	rf =>		sub { ($_->a + $_->po) / $_->f_inn * 9 },
	fpct =>		sub { ($_->po + $_->a) / ($_->po + $_->a + $_->e) },
    );
}

sub new
{
    my ($class, $hash) = @_;
    return bless \%$hash, $class;
}

sub AUTOLOAD : lvalue
{
    my $self = shift;
    my $type = ref($self) or die;
    my $name = $AUTOLOAD;
    $name =~ s/.*:://;
    my $ref;
    my $cachename = '!'.$name . join '!', @_;

    if ($name eq 'DESTROY') {
	# is there a better way?
	$ref = \$name;
    }
    elsif (exists $self->{$name}) {
    	$ref = \$self->{$name};
    }
    elsif (exists $self->{$cachename}) {
    	$ref = \$self->{$cachename};
    }
    elsif (exists $formula{$name}) {
#	no strict;
#	use vars qw/ $team $league /;


	my $caller = caller;
	local $_ = $self;
#	local *league = exists $self->{league} ? \$self->{league} : undef;
#	local *team = exists $self->{team} ? \$self->{team} : undef;
#	$DEBUG && print STDERR "[",__PACKAGE__,"] calculating $self->{name}'s $name, league: $league, team: $team\n";

	unless (ref $formula{$name}) {
	    $formula{$name} =~ s[(\$?)(?<!->)("?)(\b\w(?:\w|->)*)][
		my ($d, $q, $n) = ($1, $2, $3);
		if ($q) {
		    "\"$n";
		}
		elsif ($n =~ /^\d+$/) {
		    $n;
		}
		# This is for 2b, 3b.  We assume that no formula has name with a digital initial.
		elsif ($n =~ /^\d/) {
		    "\$_->{'$n'}";
		}
		else {
		    $d ? "\$$n" : "\$_->$n"
		}
	    ]eg;
	    $formula{$name} =~ s/\$team/\$_->team/g;
	    $formula{$name} =~ s/\$league/\$_->league/g;
#	    print "## $name ##\n$formula{$name}\n";
	    $formula{$name} = eval "sub { $formula{$name} }" or die $@;
	}

	eval { $self->{$cachename} = $formula{$name}->(@_); };
    	die "$@ when eval  [ $name ] of $_->{name}\n" if $@;

	$ref = \$self->{$cachename};
    }
    else {
    	$ref = \$self->{$name};
    }

    $$ref;
}

sub print
{
    my $self = shift;
    if (grep /^all$/, @_) {
	@_ = keys %$self;
    }
    for (@_) {
	if ($_ eq 'team') {
	    print $self->team->name, "\t";
	}
	else {
	    my $val = $self->$_;
	    if ($val =~ s/(\d+\.\d\d\d)(\d)\d*/$1/) {
		$val += 0.001 if $2 >= 5;
	    }

	    print "$val\t";
	}
    }
    print "\n";
}

sub define
{
    my ($self, %funcs) = @_;
    %formula = (%formula, %funcs);
}

sub formula
{
    die "undefined formula" unless exists $formula{$_[1]};
    return $formula{$_[1]};
}

sub formula_list
{
    return keys %formula;
}

sub top
{
    my ($self, $what, $num, $func) = @_;
    if (! ref $func) {
	return (sort { $b->$func <=> $a->$func } $self->$what)[0..$num-1];
    }
    return (sort $func $self->what)[0..$num-1];
}

sub bottom 
{
    my ($self, $what, $num, $func) = @_;
    if (! ref $func) {
	return (sort { $a->$func <=> $b->$func } $self->$what)[0..$num-1];
    }
    return (sort $func $self->what)[0..$num-1];
}

#sub declare
#{
#    my $self = shift;
#    $self->{$_} for (@_);
#}

1;
