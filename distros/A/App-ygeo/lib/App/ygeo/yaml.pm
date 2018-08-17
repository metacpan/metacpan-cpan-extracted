# ABSTRACT: Set of functions for working with yaml config files

package App::ygeo::yaml;
$App::ygeo::yaml::VERSION = '0.02';


use YAML::Tiny;

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(data_from_first_valid_cfg create_cfg keys_exists_no_empty);
our %EXPORT_TAGS = ( 'ALL' => [@EXPORT_OK] );


sub data_from_first_valid_cfg {
    my ( $config_files, $required_keys ) = @_;

    for my $file (@$config_files) {

        if ( -e $file ) {

            my $cfg = YAML::Tiny->read($file)->[0];

            return $cfg if keys_exists_no_empty( $cfg, $required_keys );
            next;

        }

    }

    return;
}


sub keys_exists_no_empty {
    my ( $hash, $required_keys ) = @_;

    my $i = 0;

    for my $k (@$required_keys) {
        if ( defined $hash->{$k} && length $hash->{$k} ) {
            $i++;
        }
    }

    $i == scalar @$required_keys ? 1 : 0;
}


sub create_cfg {

    my ( $cfg, @required_keys ) = @_;

    open( FILE, ">", $cfg ) || die "cannot open file $cfg: " . $!;
    print FILE "";
    close FILE;

    my $cfg_values = {};
    for my $k (@required_keys) {
        print "$k: ";
        chomp( $cfg_values->{$k} = <STDIN> );
    }

    my $yaml = YAML::Tiny->new($cfg_values);
    $yaml->write($cfg);

    return $cfg_values;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::ygeo::yaml - Set of functions for working with yaml config files

=head1 VERSION

version 0.02

=head1 SYNOPSIS

    use App::ygeo::yaml qw[:ALL];
    
    my @config_files = (
        File::Spec->catfile(getcwd(), '.ygeo'), 
        $ENV{"HOME"}.'/.ygeo'
    );
    my @required_keys = qw/api_key city/;

    my $params = data_from_first_valid_cfg( \@config_files, \@required_keys );
    $params = create_cfg($config_files[0], @required_keys) unless $params;

=head1 data_from_first_valid_cfg

Check for first valid config and return data from it as hash

    data_from_first_valid_cfg( [ '.ygeo', '~/.ygeo' ], [ 'apikey', 'city'] );

If no valid config found return undef

=head1 keys_exists_no_empty

Check that all required keys exists and their values are not empty

    keys_exists_no_empty( { api_key => 1111, city => 'ROV' } , ['api_key', 'city'] )

=head1 create_cfg

Create config in current directory with required parameters

    create_cfg( '.ygeo', 'apikey', 'city' );

Will create user promt 

Return hash with inputed parameters

=head1 AUTHOR

Pavel Serikov <pavelsr@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Pavel Serikov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
