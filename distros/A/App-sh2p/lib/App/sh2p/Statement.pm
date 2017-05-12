package App::sh2p::Statement;

use strict;
use warnings;
use Carp;
use Scalar::Util qw(refaddr);

use App::sh2p::Utils;
use App::sh2p::Parser;

sub App::sh2p::Parser::convert(\@\@);
our $VERSION = '0.06';
###########################################################################

my %tokens;
my %types;
my %stdin;
my %stdout;
my %stderr;

###########################################################################

sub new {
    my ($class) = @_;
    my $this = bless \do{my $some_scalar}, $class;
    my $key = refaddr $this;
    
    $tokens{$key} = [];
    $types {$key} = [];
    
    return $this;
}

###########################################################################
# Create a new object as a copy of this
sub copy {
    my ($this) = @_;
    my $key = refaddr $this;
    
    my $new = bless \do{my $some_scalar}, ref($this);
    my $newkey = refaddr $new;
    
    $tokens{$newkey} = [];
    push @{$tokens{$newkey}}, @{$tokens{$key}};
    
    $types {$newkey} = [];
    push @{$types{$newkey}}, @{$types{$key}};
    
    return $new;
}

###########################################################################

sub DESTROY {
    my ($this) = @_;
    my $key = refaddr $this;
    
    $tokens{$key} = undef;
    $types {$key} = undef;
}

###########################################################################

sub tokenise {
    my ($this, $line) = @_;
    my $key = refaddr $this;
    
    push @{$tokens{$key}}, App::sh2p::Parser::tokenise ($line);
}

###########################################################################

sub add_token {
    my ($this, $token_text) = @_;
    my $key = refaddr $this;
    
    push @{$tokens{$key}}, $token_text;
}

###########################################################################

sub add_break {
    my ($this) = @_;
    my $key = refaddr $this;
        
    push @{$tokens{$key}}, set_break();
}

###########################################################################

sub push_case {
    my ($this) = @_;
    my $key = refaddr $this;

    App::sh2p::Compound::push_case (@{$tokens{$key}});

}

###########################################################################

sub identify_tokens {
    my ($this, $nested) = @_;
    my $key = refaddr $this;

    if ( @{$tokens{$key}} ) {
        push @{$types{$key}}, 
             App::sh2p::Parser::identify ($nested, @{$tokens{$key}});
    }    
}

###########################################################################

sub convert_tokens {
    my ($this) = @_;
    my $key = refaddr $this;

    if ( @{$tokens{$key}} ) {
        App::sh2p::Parser::convert (@{$tokens{$key}}, @{$types{$key}});
    }
}

###########################################################################

1;