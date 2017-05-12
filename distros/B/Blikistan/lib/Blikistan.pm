package Blikistan;
use strict;
use warnings;
use Carp qw/croak/;

=head1 NAME

Blikistan - Create a blog from content in a wiki

=head1 SYNOPSIS

  print CGI::header();
  my $b = Blikistan->new( rester => $r );
  $b->print_blog;

=head1 DESCRIPTION

Blikistan is a simple shiv that takes content and configuration
data from a Socialtext workspace, and generates a HTML blog
using a template.

Blikistan's unique design features a MagicEngine that can be 
written in any language.  The MagicEngine fetches the blog
config and blog posts using the Socialtext REST API.

Blikistan wants to ultimately have several different MagicEngines,
each in a different language so that blog authors have the choice
of which language their blog is powered by.

Blikistan is a blogging tool named after the small ex-Soviet country
Blikistan. Blikistan (the software) features a magic engine which pulls
all the blog configuration and postings from a Socialtext Wiki.
Blikistan (the country) has a population of 32,768 people, and the
population is fully literate. Blikistan's Government never meets in
person, all communication and planning is done on a wiki.  Blikistan
(the software) is the only blogging software that allows the blogger to
choose which language their blog will be powered by. The Magic Engine
can be implemented in any language using Perl's Inline modules. In
Blikistan (the country) taxes are filed online using SocialCalc.
Blikistan (both the country and software) is completely paperless.

=cut

our $VERSION = '0.06';

=head1 FUNCTIONS

=head2 new

Creates a new Blikistan blog.  Read the code for how to pass options in.

=cut

sub new {
    my $class = shift;
    my %opts  = @_;

    my $self = {
        magic_opts => { },
        magic_engine => 'perl',
        %opts,
    };

    # Defaults
    $self->{magic_opts}{config_page}       ||= 'Blog Config';
    $self->{magic_opts}{blog_tag}          ||= 'blog post';
    $self->{magic_opts}{show_latest_posts} ||= 5;

    if (!$self->{magic_opts}{template_name}) {
        $self->{magic_opts}{template_page}     ||= 'Blog Template';
    }

    croak 'rester is mandatory' unless $self->{rester};

    bless $self, $class;
    return $self;
}

=head2 print_blog

Creates a MagicEngine and asks it to print the page.

=cut

sub print_blog {
    my $self = shift;

    my $magic_class = "Blikistan::MagicEngine::"
                       . ucfirst($self->{magic_engine});
    eval "require $magic_class";
    die if $@;

    my $me = $magic_class->new(
        rester => $self->{rester},
        %{ $self->{magic_opts} },
    );
    my $output;
    eval {
        $output = $me->print_blog;
    };
    warn $@ if $@;
    return $output;
}

=head1 AUTHOR

Luke Closs, C<< <luke.closs at 5thplane.com> >>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
