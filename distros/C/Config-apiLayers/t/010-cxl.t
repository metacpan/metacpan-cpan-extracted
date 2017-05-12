use Test::More tests => 9;
BEGIN { use_ok('Config::apiLayers'); 
      };


    # Note the missing getoptlong configuration for area
    my $cfg = new Config::apiLayers({
        autoproto => 1,
        attributes => [
            { name        => 'length',
              validator   => sub { return $_[2] > 0 ? $_[2] : undef },
              getoptlong  => 'length|l:i',
              description => "The length of a rectangle"
            },
            { name        => 'width',
              validator   => sub { return $_[2] > 0 ? $_[2] : undef },
              getoptlong  => 'width|w:i',
              description => "The width of a rectangle"
            },
            { name        => 'area',
              validator   => sub { return undef }  # do not allow storing any value
            }
        ]
    });
    ok ( defined($cfg) && ref $cfg eq 'Config::apiLayers', 'new()' );

    # Set the default values
    $cfg->config({
        data => {
            'length' => 6,
            'width' => 10,
            'area' => sub {
                my $cfg = shift;
                return ($cfg->apicall('length') * $cfg->apicall('width'))
            }
        }
    });
    my $width = $cfg->width;
    ok ( defined($width) && $width == 10, 'auto-prototype data retrieval' );

    my $getoptlong_config = $cfg->exportdata({ cfg => 'getoptlong' });
    ok ( defined($getoptlong_config) && ref $getoptlong_config eq 'ARRAY', 'exportdata cfg=>getoptlong' );

    my $attr_descriptions = $cfg->exportdata({ cfg => 'descriptions' });
    ok ( defined($attr_descriptions) && ref $attr_descriptions eq 'ARRAY', 'exportdata cfg=>descriptions' );

    $cfg->add_layer({ data => { 'length' => 8 } });

    my $data_export = $cfg->exportdata({ data => 0 });
    ok ( defined($data_export)
         && ref $data_export eq 'HASH'
         && $data_export->{'length'} == 6
         , 'exportdata data=>0' );

    my $data_export = $cfg->exportdata({ data => [0,1] });
    ok ( defined($data_export)
         && ref $data_export eq 'HASH'
         && $data_export->{'length'} == 8
         , 'add_layer and exportdata data=>[0,1]' );

    $cfg->add_layer();
    $cfg->importdata({ data => { length => 22 } });
    my $length = $cfg->length;
    ok ( defined($length) && $length == 22, 'add_layer+importdata and data retrieval' );

    my $area = $cfg->area;
    ok ( defined($area) && $area == 220, 'property value function data computation retrieval' );
