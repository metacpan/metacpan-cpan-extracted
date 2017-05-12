package App::perlfind::Plugin::Label;
use strict;
use warnings;
use App::perlfind;
our $VERSION = '2.07';

App::perlfind->add_trigger(
    'matches.add' => sub {
        my ($class, $word, $matches) = @_;

     # Is it a label (ends with ':')? Do this after %found_in, because there are
     # special labels such as 'SKIP:' and 'TODO:' that map to Test::More
        if ($$word =~ /^\w+:$/) { push @$matches, 'perlsyn' }
    }
);
1;
__END__

=pod

=head1 NAME

App::perlfind::Plugin::Label - Plugin for labels

=head1 SYNOPSIS

    # perlfind FOO:
    # (runs `perldoc perlsyn`)

=head1 DESCRIPTION

This plugin for L<App::perlfind> checks whether the search term looks like a
label and if so, adds C<perlsyn> to the match results.

