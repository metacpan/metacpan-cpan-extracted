package App::perlfind::Plugin::Functions;
use strict;
use warnings;
use App::perlfind;
use Pod::Functions;
our $VERSION = '2.07';

# Use a look-up hash, so duplicates that appear more than once in
# %Kinds are deduped; also add cleaned versions of functions found in
# %Kinds. For example, for "qw/STRING/" also add "qw"; for "y///" also
# add "y"; for "-X" also add "X".

my %is_function;
for my $function (map { @$_ } values %Kinds) {
    $is_function{$function}++;
    (my $cleaned = $function) =~ s!/STRING/!!;
    $cleaned =~ s/[^a-z]//g;
    $is_function{$cleaned}++;
}
App::perlfind->add_trigger(
    'matches.add' => sub {
        my ($class, $word, $matches) = @_;
        if ($is_function{$$word}) {
            # Add perlop as well because some thing are found there:
            # "s", "m", "tr" etc.; see Pod::Perldoc

            push @$matches, qw(perlfunc perlop);
        } elsif ($$word =~ /-[rwxoRWXOeszfdlpSbctugkTBMAC]/) {
            $$word = '-X';
            push @$matches, qw(perlfunc perlop);
        } elsif ($$word eq 'PROPAGATE') {
            $$word = 'die';
            push @$matches, qw(perlfunc perlop);
        }
    }
);
1;
__END__

=pod

=head1 NAME

App::perlfind::Plugin::Functions - Easier access to docs for built-in function

=head1 SYNOPSIS

    # perlfind splice
    # (is the same as "perlfind -f splice")

    # perlfind -- -r
    # shows the -X entry in perlfunc

=head1 DESCRIPTION

This plugin for L<App::perlfind> checks whether the search term looks like a
built-in function and if so, adds C<perlfunc> to the match results.

