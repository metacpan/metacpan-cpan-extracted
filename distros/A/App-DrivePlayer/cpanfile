# DrivePlayer CPAN dependencies
# Install with: cpanm --installdeps .

requires 'Google::RestApi', '>= 2.2.2';
requires 'URI';
requires 'YAML';
requires 'DBD::SQLite';
requires 'DBIx::Class';
requires 'Glib';
requires 'Gtk3';
requires 'JSON::MaybeXS';
requires 'Log::Log4perl';
requires 'Moo';
requires 'Readonly';
requires 'ToolSet';
requires 'Type::Tiny';
requires 'SQL::Translator', '0.11018';
requires 'YAML::XS';

# Optional: enables reading embedded FLAC tags during metadata fetch
recommends 'Audio::FLAC::Header';

on test => sub {
    requires 'Mock::MonkeyPatch';
    requires 'Module::Load';
    requires 'Test::Class';
    requires 'Test::Class::Load';
    requires 'Test::Compile';
    requires 'Test::Most';
    requires 'Test::Perl::Critic';
    requires 'Test::Pod';
};
