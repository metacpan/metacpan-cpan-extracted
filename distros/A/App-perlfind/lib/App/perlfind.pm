package App::perlfind;
use strict;
use warnings;
use Class::Trigger;
use Module::Pluggable require => 1;
__PACKAGE__->plugins;    # 'require' them
use parent qw(Pod::Cpandoc);
our $VERSION = '2.07';

# separate function so it's testable
sub find_matches {
    my $word = shift;
    my @matches;
    __PACKAGE__->call_trigger('matches.add', \$word, \@matches);
    return ($word, @matches);
}

sub grand_search_init {
    my ($self, $pages, @found) = @_;
    my (@new_pages, $done_opt_f, $done_opt_v);
    for my $page (@$pages) {

        # $page is a search term, see Pod::Perldoc
        my @matches;
        ($page, @matches) = find_matches($page);

        # If perlfunc or perlvar are indicated, set options as though
        # -f or -v were given, respectively, so Pod::Perldoc will only
        # show the relevant part of that document.
        if (grep { $_ eq 'perlfunc' } @matches) {
            $self->opt_f_with($page) unless $done_opt_v++;
        }
        if (grep { $_ eq 'perlvar' } @matches) {
            $self->opt_v_with($page) unless $done_opt_f++;
        }
        if (@matches) {
            push @new_pages, @matches;
        } else {

            # pass through; maybe someone higher up knows what to do
            # with it
            push @new_pages, $page;
        }
    }
    $self->SUPER::grand_search_init(\@new_pages, @found);
}

sub opt_V {
    my $self = shift;
    print "perlfind v$VERSION, ";
    $self->SUPER::opt_V(@_);
}

1;
__END__

=pod

=head1 NAME

App::perlfind - A more knowledgeable perldoc

=head1 SYNOPSIS

    # perlfind UNIVERSAL::isa
    # (runs `perldoc perlobj`)

    # Include features of cpandoc and perldoc:

    # perlfind File::Find
    # perlfind -m Acme::BadExample | grep system
    # vim `perlfind -l Web::Scraper`
    # perlfind -q FAQ Keyword

=head1 DESCRIPTION

C<perlfind> is like C<cpandoc> and therefore also like C<perldoc>
except it knows about more things. Try these:

    perlfind xor
    perlfind foreach
    perlfind isa
    perlfind AUTOLOAD
    perlfind TIEARRAY
    perlfind INPUT_RECORD_SEPARATOR
    perlfind '$^F'
    perlfind '\Q'
    perlfind PERL5OPT
    perlfind :mmap
    perlfind __WARN__
    perlfind __PACKAGE__
    perlfind head4
    perlfind UNITCHECK

If C<perlfind> doesn't know about a search term, it will delegate the
search to L<Pod::Cpandoc> and ultimately C<Pod::Perldoc>.

=head1 FUNCTIONS

=head2 find_matches

Takes a word and returns the matches for that word. It's in a separate
function to separate logic from presentation so other programs can use
this module as well.

=head1 AUTHORS

The following persons are the authors of all the files provided in
this distribution unless explicitly noted otherwise.

Marcel Gruenauer <marcel@cpan.org>, L<http://perlservices.at>

Lars Dieckow <daxim@cpan.org>

Leo Lapworth <LLAP@cuckoo.org>

=head1 COPYRIGHT AND LICENSE

The following copyright notice applies to all the files provided in
this distribution, including binary files, unless explicitly noted
otherwise.

This software is copyright (c) 2011-2015 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=begin Pod::Coverage

  grand_search_init
  opt_V

=end Pod::Coverage

