# ABSTRACT: fetch feeds and constrain with rules, all from a config file


use strict;
use warnings;

package App::Rssfilter::Cmd::runfromconfig;
{
  $App::Rssfilter::Cmd::runfromconfig::VERSION = '0.07';
}

use App::Rssfilter::Cmd -command;
use App::Rssfilter;
use Method::Signatures;
use Cwd;
use Path::Class qw<>;
use Log::Any::Adapter;

method usage_desc( $app ) {
    return $app->arg0 . ' %o';
}


method opt_spec( $app ) {
    return (
        [ 'config-file|f:s',  'config file for App::Rssfilter (searches for RssFilter.yaml if not set)', ],
        [ 'log|v',  'turn logging on' ],
    );
}

method validate_args( $opt, $args ) { }

method find_config( :$file = 'Rssfilter.yaml', :$dir = cwd() ) {
    $dir = Path::Class::dir->new( $dir )->absolute;
    for( reverse $dir->dir_list ) {
        my $filename = $dir->file( $file );
        return $filename if -r $filename;
        last; # directory search later
        $dir = $dir->parent;
    }
    return $file;
}

method execute( $opt, $args ) {
    my $yaml_config = Path::Class::file( $opt->config_file // $self->find_config );
    Log::Any::Adapter->set( 'Stdout' ) if $opt->log;
    App::Rssfilter->from_yaml( scalar $yaml_config->slurp )->update();
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Rssfilter::Cmd::runfromconfig - fetch feeds and constrain with rules, all from a config file

=head1 VERSION

version 0.07

=head1 SYNOPSIS

    rssfilter runfromconfig [ --config-file|-f Rssfilter.yaml ] [ --log|-v ]

This command reads a configuration file in YAML format, and updates all of the groups in the file. The YAML should describe a hash whose schema matches that described in L<App::Rssfilter::FromHash/from_hash>.

=head1 OPTIONS

=head2 -f, --config-file

Path to config file; default is C<Rssfilter.yaml> in the current directory.

=head2 -v, --log

Turns on logging; default is off.

=head1 AUTHOR

Daniel Holz <dgholz@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Daniel Holz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
