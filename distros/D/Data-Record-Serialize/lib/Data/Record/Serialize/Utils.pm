package Data::Record::Serialize::Utils;

use strict;
use warnings;

use Exporter qw[ import ];

our @EXPORT_OK = qw[ load_yaml load_json ];

use List::Util qw[ first ];
use Class::Load qw[ load_first_existing_class is_class_loaded ];

sub load_class {

    return
	 ( first { is_class_loaded $1 } @_ )
      || ( load_first_existing_class  @_ );

}

sub load_yaml {

    load_class qw[ YAML::Tiny YAML::XS YAML::Syck YAML ];

}

sub load_json {

    load_class qw[ JSON::PP JSON::Tiny JSON::XS JSON ];

}



1;
