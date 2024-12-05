use Test2::V0 -no_srand => 1;
use Data::Section::Pluggable;

is(
    Data::Section::Pluggable->new,
    object {
        call [add_plugin => 'trim'] => object {
            prop isa => 'Data::Section::Pluggable';
        };
        call get_data_section => hash {
            field 'foo.txt' => "here  \n  there";
            field 'bar.t' => "  here  \n";
            etc;
        };
    },
    'add_plugin',
);

is(
    Data::Section::Pluggable->new,
    object {
        call [add_plugin => trim => extensions => ['txt','t']] => object {
            prop isa => 'Data::Section::Pluggable';
        };
        call get_data_section => hash {
            field 'foo.txt' => "here  \n  there";
            field 'bar.t' => "here";
            etc;
        };
    },
    'add_plugin',
);

done_testing;

__DATA__
@@ foo.txt

  here  
  there  



@@ bar.t
  here  
__END__
