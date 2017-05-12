package App::Chorus;
BEGIN {
  $App::Chorus::AUTHORITY = 'cpan:YANICK';
}
# ABSTRACT: Markdown-based slidedeck server app
$App::Chorus::VERSION = '1.1.0';
use 5.10.0;

use Dancer ':syntax';

use App::Chorus::Slidedeck;

get '/' => sub {
    template 'index' => {
        presentation => presentation()->html_body,
        title => presentation()->title,
        author => presentation()->author,
        theme => presentation()->theme,
    };
};

get '/**' => sub {
    my $path = join '/', @{ (splat)[0] };

    pass unless $App::Chorus::local_public;

    $path = join '/', $App::Chorus::local_public, $path;

    pass unless -f $path;

    send_file $path, system_path => 1;
};

sub presentation {
    state $presentation;

    if ( not($presentation) or config->{reload_presentation} ) {
        $presentation = App::Chorus::Slidedeck->new(
            src_file => setting 'presentation'
        );
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Chorus - Markdown-based slidedeck server app

=head1 VERSION

version 1.1.0

=HEAD1 DESCRIPTION

L<Dancer> application module for C<chorus>. See C<chorus>'s manpage for
details on how to use it.

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
