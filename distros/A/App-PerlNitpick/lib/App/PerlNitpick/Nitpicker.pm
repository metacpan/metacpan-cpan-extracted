package App::PerlNitpick::Nitpicker;
use Moose;

has file => (
    is => 'ro',
    required => 1,
    isa => 'Str',
);

has rules => (
    is => 'ro',
    required => 1,
    isa => 'ArrayRef[Str]',
);

has inplace => (
    is => 'ro',
    required => 1,
    default  => 0,
    isa => 'Bool',
);

use PPI::Document;

# use Module::Find qw(useall);
# my @rules = sort { $a cmp $b } useall App::PerlNitpick::Rule;

# perl -Mlib=local -Ilib -MModule::Find=findallmod -E 'say "use $_;" for findallmod("App::PerlNitpick::Rule")'
use App::PerlNitpick::Rule::AppendUnimportStatement;
use App::PerlNitpick::Rule::DedupeIncludeStatements;
use App::PerlNitpick::Rule::MoreOrLessSpaces;
use App::PerlNitpick::Rule::QuoteSimpleStringWithSingleQuote;
use App::PerlNitpick::Rule::RemoveEffectlessUTF8Pragma;
use App::PerlNitpick::Rule::RemoveTrailingWhitespace;
use App::PerlNitpick::Rule::RemoveUnusedImport;
use App::PerlNitpick::Rule::RemoveUnusedInclude;
use App::PerlNitpick::Rule::RemoveUnusedVariables;
use App::PerlNitpick::Rule::RewriteHeredocAsQuotedString;
use App::PerlNitpick::Rule::RewriteWithAssignmentOperators;

my @rules = qw(AppendUnimportStatement DedupeIncludeStatements MoreOrLessSpaces QuoteSimpleStringWithSingleQuote RemoveEffectlessUTF8Pragma RemoveUnusedImport RemoveUnusedInclude RemoveUnusedVariables RewriteHeredocAsQuotedString RewriteWithAssignmentOperators);

sub list_rules {
    my ($class) = @_;
    for my $rule (@rules) {
        $rule =~ s/\A .+ :://x;
        print "$rule\n";
    }
    return;
}

sub rewrite {
    my ($self) = @_;

    my $ppi = PPI::Document->new( $self->file ) or return;
    for my $rule (@{$self->rules}) {
        my $rule_class = 'App::PerlNitpick::Rule::' . $rule;
        $ppi = $rule_class->new->rewrite($ppi);
    }
    if ($self->inplace) {
        $ppi->save( $self->file );
    } else {
        $ppi->save( $self->file . ".new" );
    }
    return;
}

1;
