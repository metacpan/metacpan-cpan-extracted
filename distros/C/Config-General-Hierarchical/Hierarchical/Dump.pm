# Config::General::Hierarchical::Dump.pm - Hierarchical Generic Config Dumper Module

package Config::General::Hierarchical::Dump;

$Config::General::Hierarchical::Dump::VERSION = 0.07;

use strict;
use warnings;

use Config::General::Hierarchical;

sub deep_dump {
    my ( $names, $cfg, $errors ) = @_;

    my @return;

    foreach my $key ( sort keys %{ $cfg->value } ) {
        my $file  = $cfg->value->{$key}->file;
        my $name  = join( '->', @$names, $key );
        my $value = eval { $cfg->get($key); };

        if ($@) {
            my @tmp = ( $name, 'error;', $file );

            push @return,  \@tmp;
            push @$errors, \@tmp;
        }
        elsif ( defined $value ) {
            if ( eval { $value->isa('Config::General::Hierarchical') } ) {
                push @$names, $key;
                push @return, deep_dump( $names, $value, $errors );
                pop @$names;
            }
            else {
                push @return, translate_value( $name, $value, $file );
            }
        }
        else {
            push @return, [ $name, 'undef;', $file ];
        }
    }

    return @return;
}

sub do_all {
    my ( $class, $file_name, $params_array, $parser_class ) = @_;

    return () unless $file_name;

    my ( $check, $file, $fixed_length, $help, $json );
    my ( $sfile, $stfile );
    my $error = '';

    parse_options( $params_array, \$error, \$check, \$file, \$fixed_length,
        \$help, \$json );

    return <<EOF if $help;
$error Usage: $0
Dumps the Config::General::Hierarchical configuration file itself

 -c, --check          if present, prints only the variables that do
                      not respect syntax constraint
 -f, --file           shows in which file variables are defined
 -l, --fixed-length   formats output as fixed length fields
 -h, --help           prints this help and exits
 -j, --json           prints output as json
EOF

    if ($parser_class) {
        eval "require $parser_class";
    }
    else {
        $parser_class = $class->parser;
    }

    my ( $cfg, @errors );

    eval { $cfg = $parser_class->new( file => $file_name ); };

    return "Parsing error: $@\n" if $@;

    return json_dump($cfg) if $json;

    my @output = deep_dump( [], $cfg, \@errors );
    my $output = ( $check && scalar @errors ) ? \@errors : \@output;
    my $format = make_format( $fixed_length, $file, $output );
    my $base_dir = find_base_dir( $cfg->opt->files );

    my @files;
    my @return;

    if ($file) {
        my $base_dir_len = 1 + length $base_dir;

        push @return, "Configuration files base dir: $base_dir/\n";

        @files = map substr( $_, $base_dir_len ), @{ $cfg->opt->files };

        if ( scalar @files > 1 ) {

            push @return, "Files inheritance structure:\n";
            push @return, dump_struct( $cfg->opt->struct->{0}, \@files );
        }
    }

    push @return,
      map( ref $_
        ? sprintf( $format, $_->[0], $_->[1], $files[ $_->[2] ] )
        : $_,
        @$output );

    return @return;
}

sub dump_struct {
    my ( $struct, $files, $key, $lvl ) = @_;

    $key ||= 0;
    $lvl ||= 1;

    my @ret = ( ( '  ' x $lvl ) . $files->[$key] . "\n" );

    push @ret, map dump_struct( $struct->{$_}, $files, $_, $lvl + 1 ),
      keys %$struct;

    return @ret;
}

sub find_base_dir {
    my ($files) = @_;

    my @mcp = split '/', $files->[0];
    my $last = scalar @$files;

    pop @mcp;

    for ( my $i = 1 ; $i < $last ; ++$i ) {
        my @this = split '/', $files->[$i];

        for ( my $j = 0 ; $j < scalar @mcp ; ++$j ) {
            if ( $mcp[$j] ne $this[$j] ) {
                splice @mcp, $j;
            }
        }
    }

    return join '/', @mcp;
}

sub import {
    my ( $class, @pars ) = @_;

    return if caller ne 'main';

    print join '', $class->do_all( $0, \@ARGV, $pars[0] );

    exit;
}

sub json_dump {
    my ($cfg) = @_;

    my $return = '{';

    foreach my $key ( sort keys %{ $cfg->value } ) {
        $return .= "\"$key\":";

        my $value = eval { $cfg->get($key); };

        if ($@) {
            $return .= '"error",';
        }
        elsif ( defined $value ) {
            if ( eval { $value->isa('Config::General::Hierarchical') } ) {
                $return .= json_dump($value) . ',';
            }
            else {
                $return .= translate_json($value);
            }
        }
        else {
            $return .= 'null,';
        }
    }

    chop $return;

    return $return . '}';
}

sub make_format {
    my ( $fixed_length, $file, $output ) = @_;

    my $format = "\%s = \%s\n";

    if ($fixed_length) {
        my $maxlen = 0;
        my $len;

        foreach (@$output) {
            next unless ref $_;

            $len = length $_->[0];

            $maxlen = $len if $len > $maxlen;
        }

        $format = '%-' . $maxlen . "s = %";
        $maxlen = 0;

        foreach (@$output) {
            next unless ref $_;

            $len = length $_->[1];

            $maxlen = $len if $len > $maxlen;
        }

        if ($file) {
            $format .= '-' . $maxlen . "s \%s\n";
        }
        else {
            $format .= "s\n";
        }
    }
    else {
        $format = "\%s = \%s \%s\n" if $file;
    }

    return $format;
}

sub parse_options {
    my ( $params_array, $error, $check, $file, $fixed_length, $help, $json ) =
      @_;

    foreach my $param (@$params_array) {
        if ( substr( $param, 0, 1 ) ne '-' ) {
            $$help  = 1;
            $$error = "Unknown options '$param'\n\n";
            return;
        }

        if ( substr( $param, 0, 2 ) eq '--' ) {
            if ( $param eq '--check' ) {
                $$check = 1;
            }
            elsif ( $param eq '--file' ) {
                $$file = 1;
            }
            elsif ( $param eq '--fixed-length' ) {
                $$fixed_length = 1;
            }
            elsif ( $param eq '--help' ) {
                $$help = 1;
            }
            elsif ( $param eq '--json' ) {
                $$json = 1;
            }
            else {
                $$help  = 1;
                $$error = "Unknown options '$param'\n\n";
                return;
            }
        }
        else {
            for ( my $i = 1 ; $i < length $param ; ++$i ) {
                my $p = substr $param, $i, 1;

                if ( $p eq 'c' ) {
                    $$check = 1;
                }
                elsif ( $p eq 'f' ) {
                    $$file = 1;
                }
                elsif ( $p eq 'h' ) {
                    $$help = 1;
                }
                elsif ( $p eq 'j' ) {
                    $$json = 1;
                }
                elsif ( $p eq 'l' ) {
                    $$fixed_length = 1;
                }
                else {
                    $$help  = 1;
                    $$error = "Unknown options '-$p'\n\n";
                    return;
                }
            }
        }
    }
}

sub parser { return 'Config::General::Hierarchical'; }

sub translate_json {
    my ($value) = @_;

    unless ( ref $value ) {
        $value =~ s/\n/\\n/g;

        return "\"$value\",";
    }

    my $ret = '[';

    foreach my $val (@$value) {
        $val =~ s/\n/\\n/g;
        $ret .= "\"$val\",";
    }

    chop $ret;

    return $ret . '],';
}

sub translate_value {
    my ( $name, $value, $file ) = @_;

    unless ( ref $value ) {
        return [ $name, "'$value';", $file ] if $value !~ /\n/;

        my $return = [ $name, '<<EOF;', $file ];

        return ( $return, $value . "EOF\n" ) if $value =~ /\n$/;

        return ( $return, $value . "//--new line added\nEOF\n" );
    }

    my @ret;
    my $simple = 1;

    foreach my $val (@$value) {
        $simple = 0 if $val =~ /\n/;
    }

    return [ $name, "( '" . join( "', '", @$value ) . "' );", $file ]
      if $simple;

    return ( [ $name, '*;', $file ],
        "* = ( '" . join( "', '", @$value ) . "' );\n" );
}

1;

__END__

=head1 NAME

Config::General::Hierarchical::Dump - Hierarchical Generic Config Dumper Module

=head1 SYNOPSIS

Simple use:

 $
 $ cat example.conf
 #!/usr/local/bin/perl -MConfig::General::Hierarchical::Dump
 variable1 value
 variable2
 <node>
  key value
 </node>
 $
 $ chmod 755 example.conf
 $ ./example.conf
 node->key = 'value'
 variable1 = 'value'
 variable2 = ''
 $
 $

Full use:

 package MyConfig::Dump;
 #
 use base 'Config::General::Hierarchical::Dump';
 use MyConfig;
 #
 sub parser {
  return 'MyConfig';
 }

=head1 DESCRIPTION

This module provides an easy way to dump configuration files written for
L<Config::General::Hierarchical>.

=head1 SUBROUTINES/METHODS

=over

=item import

Implicitally called by B<-M> perl option, it reads the configuration file itself, dumps
it to I<standard output> and exits.

=item parser

Returns the class name to be used to parse the file, by default
C<Config::General::Hierarchical>. If you exetend C<Config::General::Hierarchical> with
so many customization that you need to use your own class to parse the file, you can
extend C<Config::General::Hierarchical::Dump> as well and simply redefine this method
to return your own class name and use this second new class as parameter of B<-M> perl
option.

=back

=head1 CMD LINE PARAMETERS

=over

=item -c, --check

This can beusefull to find immediatelly which are eventaul B<configuration variables> not
respecting the B<syntax constraint>

=item -f, --file

Makes the source file (foreach variable) to be printed.

=item -l, --fixed-length

Formats the output as fixed characters length.

=item -h, --help

Prints an help screen and exits.

=item -j, --json

Prints the output as a json string.

=back

=head1 BUGS AND INCOMPATIBILITIES

Please report.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2007-2009 Daniele Ricci

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

Daniele Ricci <icc |AT| cpan.org>

=head1 VERSION

0.07

=cut
