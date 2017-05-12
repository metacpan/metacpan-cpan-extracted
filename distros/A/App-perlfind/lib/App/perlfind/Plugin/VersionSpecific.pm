package App::perlfind::Plugin::VersionSpecific;
use strict;
use warnings;
use App::perlfind;
our $VERSION = '2.07';

App::perlfind->add_trigger(
    'matches.add' => sub {
        my ($class, $word, $matches) = @_;
        if ($$word =~ /^__(PACKAGE|LINE|FILE)__$/ && $] =~ /^5\.0(08|10|12|14)/) {
            push @$matches, qw(perldata);
        }
    }
);
1;
__END__

=pod

=head1 NAME

App::perlfind::Plugin::Legacy - Version-specific mappings

=head1 SYNOPSIS

    # perlfind __PACKAGE__
    # behaves differently in 5.8.9 and 5.18.2, for example

=head1 DESCRIPTION

This plugin for L<App::perlfind> provides version-specific mappings. It does so
in a very rudimentary way; it would be better if the whole architecture of
C<perlfind> would take perl versions into account.
