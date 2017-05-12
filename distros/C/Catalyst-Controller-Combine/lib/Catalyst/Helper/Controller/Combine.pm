package Catalyst::Helper::Controller::Combine;
{
  $Catalyst::Helper::Controller::Combine::VERSION = '0.15';
}

use strict;

=head1 NAME

Catalyst::Helper::Controller::Combine - Helper for Combine Controllers

=head1 VERSION

version 0.15

=head1 SYNOPSIS

    script/create.pl controller Js Combine
    script/create.pl controller Css Combine

=head1 DESCRIPTION

Helper for Combine Controllers.

=head2 METHODS

=head3 mk_compclass

=cut

sub mk_compclass {
    my ( $self, $helper ) = @_;
    my $file = $helper->{file};
    
    my $ext = lc($helper->{name}) || 'xx';
    $ext =~ s{\A .* ::}{}xms;
    
    my %var = (ext => $ext, replace => "\n", extra => "\n");
    if ($ext eq 'js')  { 
        $var{mimetype} = 'application/javascript';
        $var{minifier} = "# uncomment if desired and do not import namespace::autoclean!\n# use JavaScript::Minifier::XS qw(minify);";

        $var{depend} = <<EOF;

    # aid for the prototype users (site.js is main file)
    #   --> place all .js files directly into root/static/js!
    #     scriptaculous => 'prototype',
    #     builder       => 'scriptaculous',
    #     effects       => 'scriptaculous',
    #     dragdrop      => 'effects',
    #     slider        => 'scriptaculous',
    #     site          => 'dragdrop',
    #
    # aid for the jQuery users (site.js is main file)
    #   --> place all .js files including version-no directly into root/static/js!
    #     'jquery.metadata'     => 'jquery-1.6.2'
    #     'jquery.form-2.36'    => 'jquery-1.6.2'
    #     'jquery.validate-1.6' => [qw(jquery.form-2.36 jquery.metadata)]
    #     site                  => [qw(jquery.validate-1.6 jquery-ui-1.8.1)]
EOF
        $var{sample_minifier} = <<'EOF';

#    usually you will do more :-)
#    $text =~ s{\\s+}{ }xmsg;
EOF
    }
    if ($ext eq 'css') { 
        $var{mimetype} = 'text/css'; 
        $var{minifier} = "# uncomment if desired and do not import namespace::autoclean!\n# use CSS::Minifier::XS qw(minify);";

        $var{depend} = <<EOF;

    #  (site.css is main file)
    #     page    => [ qw(forms table) ],
    #     site    => [ qw(reset page jquery-ui-1.8.13) ],
EOF
        $var{replace} = <<EOF;

    #                    # change jQuery UI's links to images
    #                    # assumes that all images for jQuery UI reside under static/images
    #     'jquery-ui' => [ qr'url\(images/' => 'url(/static/images/' ],
EOF
        $var{extra} = <<'EOF';

    #
    #   execute @import statements during combining
    #   CAUTION: media-types cannot get evaluated, everything is included!
    # include => [
    #     qr{\@import \s+ (?:url\s*\()? ["']? ([^"')]+) ["']? [)]? .*? ;}xms
    # ],
EOF
        $var{sample_minifier} = <<'EOF';

#     #
#     # let `sass` convert our scss-style into css
#     # borrowed from Tatsuhiko Miyagawa's Plack::Middleware::File::Sass
#     #
#     
#     use IPC::Open3 'open3';
#     
#     my $pid = open3(my $in, my $out, my $err,
#                     '/usr/bin/sass', '--stdin', '--scss');
#     print $in $text;
#     close $in;
#     
#     $text = join '', <$out>;
#     waitpid $pid, 0;
EOF

    }
    
    $helper->render_file( 'compclass', $file, \%var );
}

=head1 SEE ALSO

L<Catalyst::Manual>, L<Catalyst::Helper>

=head1 AUTHOR

Wolfgang Kinkeldei, E<lt>wolfgang@kinkeldei.deE<gt>

=head1 LICENSE

This library is free software . You can redistribute it and/or modify
it under the same terms as perl itself.

=cut

1;

__DATA__

__compclass__
package [% class %];

use Moose;
BEGIN { extends 'Catalyst::Controller::Combine' }

[% minifier %]

__PACKAGE__->config(
    #   optional, defaults to static/<<action_namespace>>
    # dir => 'static/[% ext %]',
    #
    #   optional, defaults to <<action_namespace>>
    # extension => '[% ext %]',
    #
    #   specify dependencies (without file extensions)
    # depend => {
[%- depend -%]
    # },
    #
    #   optionally specify replacements to get done
    # replace => {
[%- replace -%]
    # },
[%- extra -%]
    #
    #   will be guessed from extension
    # mimetype => '[% mimetype %]',
    #
    #   if you want a different minifier function name (default: 'minify')
    # minifier => 'my_own_minify',
    #
    #   uncomment if you want to get the 'expire' header set (default:off)
    # expire => 1,
    #
    #   set a different value if wanted
    # expire_in => 60 * 60 * 24 * 365 * 3, # 3 years
);

#
# defined in base class Catalyst::Controller::Combine
# uncomment and modify if you like
#
# sub default :Path {
#     my $self = shift;
#     my $c = shift;
#     
#     $c->forward('do_combine');
# }

#
# optionally, define a minifier routine of your own
#
# sub minify :Private {
#     my $text = shift;
#
[%- sample_minifier -%]
#
#     return $text;
# }

=head1 NAME

[% class %] - Combine View for [% app %]

=head1 DESCRIPTION

Combine View for [% app %]. 

=head1 SEE ALSO

L<[% app %]>

=head1 AUTHOR

[% author %]

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
