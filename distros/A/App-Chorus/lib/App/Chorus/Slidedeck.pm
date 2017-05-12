package App::Chorus::Slidedeck;
BEGIN {
  $App::Chorus::Slidedeck::AUTHORITY = 'cpan:YANICK';
}
#ABSTRACT: presentation document for Chorus
$App::Chorus::Slidedeck::VERSION = '1.1.0';
use 5.10.0;

use strict;
use warnings;

use Moose;

use Path::Tiny;
use Web::Query;
use HTML::Entities qw/ encode_entities /;
use Text::Markdown qw/ markdown /;


has src_file => (
    is => 'ro',
);

has src_markdown => (
    is => 'ro',
    lazy => 1,
    default => sub {
        my $self = shift;
        path( $self->src_file )->slurp;
    },
);

has meta => (
    is => 'rw',
);

has title => (
    is => 'ro',
    lazy => 1,
    default => sub {
        my $self = shift;
        my $bod = $self->html_body;
        $self->meta->{title} || wq($bod)->find('h1,h2,h3')->first->text()
    },
);

has author => (
    is => 'ro',
    lazy => 1,
    default => sub {
        my $self = shift;
        my $bod = $self->html_body;
        $self->meta->{author}
    },
);

has theme => (
    is => 'ro',
    lazy => 1,
    default => sub {
        my $self = shift;
        my $bod = $self->html_body;
        $self->meta->{theme} || 'default';
    },
);

has html_body => (
    is => 'ro',
    lazy => 1,
    default => sub {
        my $self = shift;
        
        my $markdown = $self->groom_markdown( $self->src_markdown );

        my $prez = markdown( $markdown );

        my $q = Web::Query->new_from_html( "<body>$prez</body>" );

    # move stuff in sections
    my $qs = Web::Query->new_from_html( "<div class='slides'></div>" );
    my $section;

    $q->contents->each(sub{
            my( $i, $elem ) = @_;

            if ( $elem->get(0)->tag =~ /^h[123456]$/ ) {
                $qs->append( "<section />" );
            }

            $elem->detach;
            $qs->find('section')->last->append($elem);
    });

    my $prev_section;
    $qs->find('section')->each(sub{
        my( $i, $elem ) = @_;

        my $head = $elem->find('h1,h2')->first or return;

        my $text = $head->text;

        if ( $text =~ s/cont'd//i ) {
            if ( $prev_section->find('section')->size == 0 ) {
                my $s = wq("<section />");
                for ( $prev_section->contents ) {
                    $_->detach;
                    $s->append($_);
                }
                $prev_section->append($s);
            }
                
            $head->text($text);
            $elem->detach;
            $prev_section->append($elem);
        }
        else {
            $prev_section = $elem;
        }

    });

    $qs->find('p')->each(sub{
            my(undef,$elem)=@_;

            if ( $elem->text =~ /^\s*\.{3}/ ) {
                (my $text = $elem->text ) =~ s/^\s*\.{3}//;
                $elem->text($text);
                if ( $elem->parent->get(0)->tag eq 'li' ) {
                    $elem->parent->add_class('fragment');
                }
                else {
                    $elem->add_class('fragment');
                }
            }

    });

    my $last_aside;
    $qs->find('aside')->each(sub{
        my $elem = $_;
        
        if ( $last_aside and $last_aside->parent->html eq $elem->parent->html ) {
            $elem->tagname('p');
            $last_aside->append( $elem );
            $elem->detach;
            return;
        }

        $last_aside = $elem;
    });

    # titles with a leading '^' want to be in the previous section
    $qs->find('h1,h2,h3')->each(sub{
        my $title = $_->html;

        return unless $title =~ s/^\s*\^//;
        $_->html($title);

        my $parent = $_->parent;
        my $prev = $parent->prev;

        unless( $prev->attr('nested') ) {
            my $new = wq( '<section nested="1" />' );
            $new->append($prev);
            $prev->replace_with($new);
            $prev = $new;
        }

        $parent->prev->append($parent);
        $parent->detach;

    });

    # titles that are lonely '---' are removed
    
    $qs->find('h1,h2,h3')->each(sub{
        return unless $_->html =~ /^\s*-+\s*$/;
        $_->html('');
    });

    $qs->find('section')->first->each(sub{
            $_->attr( 'class', $_->attr('class') . ' title_slide' );
    });

    return $qs->as_html;
    },

);

sub groom_markdown {
    my( $self, $md ) = @_;

    my %meta;
    while ( $md =~ s/^(\S+)\s*:\s*(.*)// ) {
        $meta{$1} = $2;
    }

    $self->meta( \%meta );

    # off with the commented out
    $md =~ s#^!!!\s*?$(.*?)^!!!\s*?$##xsmg;

    $md =~ s#^(```+)\s*?(\S*)$ (.*?)^\1$ #
        "<pre><code class='$2'>" 
      . encode_entities($3) 
      . '</code></pre>'#xemgs;

      $md =~ s#(?:^~\s+)(.*)#<aside class="notes">$1</aside>#xmg;
      $md =~ s#^~~~\s*?$(.*?)^~~~\s*?$#<aside class="notes">$1</aside>#xsmg;

    return $md;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Chorus::Slidedeck - presentation document for Chorus

=head1 VERSION

version 1.1.0

=head1 CHORUS ADDITIONAL MARKUP

Chorus adds a few custom shorcuts in addition of the regular Markdown syntax.

=over

=item Slides

Slides begin with a header, any one. If you want to add a vertical slide,
append a C<^> to the C<#>s.

    # A slide with a big title

    ## A slide with a slightly smaller title

    ##^ follow-up slide

    # Back to top-level

Also, the first <section> tag will be given the class 'title_slide' (useful
for css rules).

=item Metadata

Chorus accepts some pieces of metadata that can be put at the beginning of the 
document.

    title: foo
    author: Me
    theme: default

If not given, the title will default to the first header found in the
document. Likewise, the default Revealjs theme is (surprise) 'default'.

=item Speaker notes

    ~ will become 
    ~ a speaker 
    ~ note

    ~~~
    so will
    this
    ~~~

=back

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
