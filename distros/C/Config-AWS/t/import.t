use Test2::V0;
use Test2::Tools::Spec;

describe 'Import tags' => sub {
    my (%tags, $tag);
    our %functions;

    before_all 'Prepare tags' => sub {
        %tags = (
            ini  => [qw( read_file read_string read_handle )],
            aws  => [qw( config_file default_profile credentials_file )],
            read => [qw( read read_all list_profiles )],
        );
        $tags{all} = [ map { @{$_} } values %tags ];
        %functions = map { $_ => 1 } @{$tags{all}};
    };

    case 'None'  => sub { $tag = ''  };
    case ':ini'  => sub { $tag = 'ini'  };
    case ':aws'  => sub { $tag = 'aws'  };
    case ':read' => sub { $tag = 'read' };
    case ':all'  => sub { $tag = 'all'  };

    it 'Imports correct functions' => sub {
        local %functions = %functions;

        require Config::AWS;
        Config::AWS->import( $tag ? ":$tag" : () );

        my @imported = @{$tags{$tag} // []};
        delete $functions{$_} for @imported;

        my @not_imported = keys %functions;

        imported_ok(@imported) if @imported;
        not_imported_ok(@not_imported) if @not_imported;

        Config::AWS->unimport(':all');
    };
};

done_testing;
