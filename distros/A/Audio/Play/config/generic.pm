package
 Audio::Play::#OSNAME#;
require Audio::Play;
@ISA = qw(Audio::Play);
bootstrap Audio::Play::#OSNAME# $Audio::Data::VERSION;
1;
