use Module::Build;
Module::Build->subclass(
    class => 'Darcs::Inventory::Module::Build',
    code => q{
       # All this because the MANIFEST file doesn't support empty directories.
       sub ACTION_distdir {
           my ($self) = @_;
           $self->SUPER::ACTION_distdir;
           for (qw(t/darcs-2/_darcs/pristine.hashed
                   t/darcs-hashed/_darcs/pristine.hashed
                   t/darcs-old/_darcs/pristine)) {
               File::Path::mkpath($self->dist_dir."/$_", 0, oct(777));
           }
       }
     },
)->new(
    module_name => 'Darcs::Inventory',
    license     => 'perl',
    dist_author => 'David Caldwell <david@porkrind.org>',
    requires    => { 'Digest::SHA'   => 0,
                     'Time::Local'   => 0,
                     'IPC::Run'      => 0,
                     'Class::Accessor::Fast' => 0
    },
)->create_build_script;
