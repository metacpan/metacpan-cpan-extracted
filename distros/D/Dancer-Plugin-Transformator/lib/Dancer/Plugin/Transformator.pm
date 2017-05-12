use strict;
use warnings;

package Dancer::Plugin::Transformator;

# ABSTRACT: Dancer plugin for Net::NodeTransformator

use Dancer ':syntax';
use Dancer::Plugin;
use Net::NodeTransformator 0.105;

our $VERSION = '0.002';       # VERSION
our $CLASS   = __PACKAGE__;

our $NNT;

sub _get_instance {
    my $config = plugin_setting;
    if ( $config->{connect} ) {
        return Net::NodeTransformator->new( $config->{connect} );
    }
    else {
        unless ($NNT) {
            $NNT = Net::NodeTransformator->standalone;
        }
        return $NNT;
    }
}

register transform => sub {
    my ( $engine, $input, $data ) = @_;
    my $nnt = _get_instance();
    $nnt->transform( $engine, $input, $data );
};

register transform_output => sub {
    my ( $engine, $data ) = @_;
    var $CLASS = [] unless exists vars->{$CLASS};
    push @{ vars->{$CLASS} } => { engine => $engine, data => $data };
};

hook after => sub {
    my $response = shift;
    if ( exists vars->{$CLASS} ) {
        my $nnt        = _get_instance();
        my $transforms = delete vars->{$CLASS};
        foreach my $transform (@$transforms) {
            $response->content(
                $nnt->transform(
                    $transform->{engine}, $response->content,
                    $transform->{data}
                )
            );
        }
    }
};

register_plugin;

__END__

=pod

=head1 NAME

Dancer::Plugin::Transformator - Dancer plugin for Net::NodeTransformator

=head1 VERSION

version 0.002

=head1 SYNOPSIS

	use Dancer::Plugin::Transformator;
	
	set plugins => {
		Transformator => {
			connect => 'localhost:12345',
		}
	};
	
	get '/' => sub {
		transform_output 'jade';
		transform_output 'minify_html';
		return template 'index';
	};

=head1 METHODS

=head2 C<< transform($engine, $input[, $data]) >>

A wrapper method for L<Net::NodeTransformator>::transform.

=head2 C<< transform_output($engine[, $data]) >>

Creates an after-hook and transform the response content via specified engine. Multiple calls of this method causes the engines to be chained. In the synopsis example above, the content of the template output is first transformed via I<jade> and then minified. The argument C<$data> is only meaningful for I<jade> engine.

=head1 PLUGIN CONFIGURATION

The plugin needs only one setting, the C<connect> parameter. See documentation of L<Net::NodeTransformator> for more information about the syntax. If omitted, a standalone server will be started.

=head2 SEE ALSO

=over 4

=item * L<Net::NodeTransformator>

=back

1;

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/zurborg/libdancer-plugin-transformator-perl/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

David Zurborg <zurborg@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by David Zurborg.

This is free software, licensed under:

  The ISC License

=cut
