package Class::DBI::FormBuilder;

use warnings;
use strict;
use Carp();

use List::Util();
use CGI::FormBuilder 3;
use Class::DBI::FormBuilder::Meta::Table;

use UNIVERSAL::require;

use constant ME     => 0;
use constant THEM   => 1;
use constant FORM   => 2;
use constant FIELD  => 3;
use constant COLUMN => 4;

use base 'Class::Data::Inheritable';

our $VERSION = '0.483';

# process_extras *must* come 2nd last 
our @BASIC_FORM_MODIFIERS = qw( pks options file timestamp text process_extras final );

# C::FB sometimes gets confused when passed CDBI::Column objects as field names, 
# hence all the map {''.$_} column filters. Some of them are probably unnecessary, 
# but I need to track down which. UPDATE: the dev version now uses map { $_->name }
# everywhere.

# CDBI has accessor_name *and* mutator_name methods, so potentially, each column could 
# have 2 methods to get/set its values, neither of which are the column's name.

# Column objects can be queried for these method names: $col->accessor and $col->mutator

# Not sure yet what to do about caller-supplied column names. 

# General strategy: don't stringify anything until sending stuff to CGI::FB, at which point:
#   1. stringify all values
#   2. test field names to see if they are (CDBI column) objects, and if so, extract the 
#       appropriate accessor or mutator name

# UPDATE: forms should be built with $column->name as the field name, because in general 
#   form submissions will need to do both get and set operations. So the form handling 
#   methods should assume forms supply column names, and should look up column mutator/accessor 
#   as appropriate.

our %ValidMap = ( varchar   => 'VALUE',
                  char      => 'VALUE', # includes MySQL enum and set - UPDATE - not since 0.41
                  
                  enum      => 'VALUE',
                  set       => 'VALUE',
                  
                  blob      => 'VALUE', # includes MySQL text
                  text      => 'VALUE',
                  
                  integer   => 'INT',
                  bigint    => 'INT',
                  smallint  => 'INT',
                  tinyint   => 'INT',
                  int       => 'INT',
                  
                  date      => 'VALUE',
                  time      => 'VALUE',
                  datetime  => 'VALUE',
                  
                  # normally you want to skip validating a timestamp column...
                  #timestamp => 'VALUE',
                  
                  double    => 'NUM',
                  float     => 'NUM',
                  decimal   => 'NUM',
                  numeric   => 'NUM',
                  );    
                  
__PACKAGE__->mk_classdata( field_processors => {} );
__PACKAGE__->mk_classdata( post_processors  => {} );
                  
{
    # field_processors
    my $built_ins = { # default in form_pks
                      HIDDEN => [ '+HIDDEN', '+VALUE' ],
                      
                      '+HIDDEN' => sub { $_[FORM]->field( name  => $_[FIELD],
                                                          type  => 'hidden',
                                                          ) },
                                                          
                      VALUE => '+VALUE',
                      
                      '+VALUE' => sub 
                      { 
                                my $value;
                                
                                my $accessor = $_[COLUMN]->accessor;
                                 
                                eval { $value = $_[THEM]->$accessor if ref( $_[THEM] ) };
                                     
                                if ( $@ )
                                {
                                    die sprintf "Error running +VALUE on '%s' field: '%s' (value: '%s'): $@", 
                                        $_[THEM], $_[COLUMN]->accessor, defined $value ? $value : 'undef';
                                }
                                
                                $value = ''.$value if defined $value;  # CGI::FB chokes on objects
                                
                                if ( ! defined $value )
                                {
                                    # if the column can be NULL, and the value is undef, we have no way of 
                                    # knowing whether the value has never been set, or has been set to NULL
                                    if ( ! $_[ME]->table_meta( $_[THEM] )->column( $_[FIELD] )->nullable )
                                    {
                                        # but if the column can not be NULL, and the value is undef, 
                                        # set it to the default for the column
                                        $value = $_[ME]->table_meta( $_[THEM] )->column( $_[FIELD] )->default;
                                    }
                                }
                                
                                $_[FORM]->field( name  => $_[FIELD],
                                                 value => $value,   
                                                 );
                      },
                            
                      TIMESTAMP => 'READONLY',
                      
                      DISABLED => [ '+DISABLED', '+VALUE' ],
                      
                      '+DISABLED' => sub { $_[FORM]->field( name     => $_[FIELD],
                                                            disabled => 1,
                                                            class    => 'Disabled',
                                                            ) },
                           
                      READONLY => [ '+READONLY', '+VALUE' ],
                                              
                      '+READONLY' => sub { $_[FORM]->field( name     => $_[FIELD],
                                                            readonly => 1,
                                                            class    => 'ReadOnly',
                                                            ) },
                                                            
                      FILE => [ '+FILE', '+VALUE' ],
                      
                      '+FILE' => sub 
                      { 
                          my $value = $_[THEM]->get( $_[FIELD] ) if ref( $_[THEM] );
                          
                          $_[FORM]->field( name  => $_[FIELD],
                                           type  => 'file',
                                           );
                      },
                      
                      # default in form_options
                      OPTIONS_FROM_DB => [ '+OPTIONS_FROM_DB', '+VALUE' ],
                      
                      '+OPTIONS_FROM_DB' => sub 
                      {    
                          my ( $series, $multiple ) = 
                              $_[ME]->table_meta( $_[THEM] )->column( $_[FIELD] )->options;
                              
                          return unless @$series;
                        
                          $_[FORM]->field( name      => $_[FIELD],
                                           options   => $series,
                                           multiple  => $multiple,
                                           );
                      },
                      
                      '+REQUIRED' => sub { $_[FORM]->field( name      => $_[FIELD],
                                                            required  => 1,
                                                            ) },
                                                         
                      '+NULL' => sub {},
                      
                      '+ADD_FIELD' => sub { $_[FORM]->field( name     => $_[FIELD],
                                                             # need to set something to vivify the field
                                                             required => 0, 
                                                             ) },
                                                          
                      };
                      
    __PACKAGE__->field_processors( $built_ins );    
}

{
    # post processors - note that the calling code is responsible for loading prerequisites 
    #                   of a processor e.g. HTML::Tree
    my $built_ins = { 
        PrettyPrint => sub 
            {
                my ( $me, $form, $render, undef, %args ) = @_;
                
                # the <div></div> is a trick to force HTML::TB to put the 
                # noscript in the body and not in the head
                my $html_in = '<div></div>' . $render->( $form, %args );
                
                my $tree = HTML::TreeBuilder->new;
                
                $tree->store_comments( 1 );
                #$tree->ignore_unknown( 0 );
                $tree->no_space_compacting( 1 );
                #$tree->warn( 1 );     
                
                $tree->parse( $html_in );
                $tree->eof;
                
                my $html_out = $tree->guts->as_HTML( undef, '  ', {} );
                
                $tree->delete;
                
                # clean up after the <div></div> trick, and remove the outer div 
                # added by the guts() call (which removed html-head-body implicit tags)
                $html_out =~ s'^<div>\s*<div>\s*</div>'';
                $html_out =~ s'</div>$'';
                
                return $html_out;
            },
        
        # Duplicates => sub ... # removed after revision 368
        
        NoTextAreas => sub 
            {
                my ( $me, $form, $render, undef, %args ) = @_;
            
                foreach my $field ( $form->field )
                {
                    $field->type( 'text' ) if $field->type eq 'textarea';
                }   
                
                return $render->( $form, %args );
            },
        
        };
        
    __PACKAGE__->post_processors( $built_ins );    
}
    
sub import
{
    my ( $class, %args ) = @_;
    
    my $caller = caller(0);
    
    $caller->can( 'form_builder_defaults' ) || $caller->mk_classdata( 'form_builder_defaults', {} );
    
    # replace CGI::FB's render() method with a hookable version
    {
        my $render = \&CGI::FormBuilder::render;
        
        my $hookable_render = sub 
        { 
            my ( $form, %args ) = @_;
            
            if ( my $post_processor = delete( $args{post_process} ) || $form->__cdbi_original_args__->{post_process} )
            {
                # the pp can mess with the form, then render it (as in the else clause below), then mess 
                # with the HTML, before returning the HTML
                my $pp_args = $form->__cdbi_original_args__->{post_process_args};
                
                my $pp = ref( $post_processor ) eq 'CODE' ? $post_processor : $class->post_processors->{ $post_processor };
                
                return $pp->( $class, $form, $render, $pp_args, %args );           
            }
            else
            {
                return $render->( $form, %args );
            }
        };
        
        no warnings 'redefine';
        *CGI::FormBuilder::render = $hookable_render;
    }
    
    # To support subclassing, store the FB (sub)class on the caller, and use that whenever we need
    # to call an internal method on the CDBI::FB class 
    # i.e. say $them->__form_builder_subclass__ instead of __PACKAGE__
    $caller->mk_classdata( __form_builder_subclass__ => $class );
    
    # _col_name_from_mutator_or_object() needs a cache of mutator_name => column_name
    # on each CDBI class. Note that this accessor is used in a slightly unusual way, 
    # by including a key on the CDBI class. Otherwise, lookups on one class could 
    # fall through to an inherited map, rather than the map for the class we're 
    # interested in. So the map is only stored on $caller.
    $caller->mk_classdata( __mutator_to_name__ => {} );
    
    my @export = qw( as_form 
                     search_form
                     
                     as_form_with_related
                     
                     as_multiform
                     create_from_multiform
                     
                     update_or_create_from_form
                     
                     update_from_form_with_related
                     
                     retrieve_from_form
                     search_from_form 
                     search_like_from_form
                     search_where_from_form
                     
                     find_or_create_from_form 
                     retrieve_or_create_from_form
                     );
                   
    if ( $args{BePoliteToFromForm} )
    {
        no strict 'refs';
        *{"$caller\::${_}_fb"} = \&{"${_}_form"} for qw( update_from create_from );
    }
    else
    { 
        push @export, qw( update_from_form create_from_form );
    }
    
    no strict 'refs';
    *{"$caller\::$_"} = \&$_ for @export;  
}

=head1 NAME

Class::DBI::FormBuilder - Class::DBI/CGI::FormBuilder integration

=head1 SYNOPSIS


    package Film;
    use strict;
    use warnings;
    
    use base 'Class::DBI';
    use Class::DBI::FormBuilder;
    
    # for indented output:
    # use Class::DBI::FormBuilder PrettyPrint => 'ALL';
    
    # POST all forms to server
    Film->form_builder_defaults->{method} = 'post';
    
    # customise how some fields are built:
    # 'actor' is a has_a field, and the 
    # related table has 1000's of rows, so we don't want the default popup widget,
    # we just want to show the current value
    Film->form_builder_defaults->{process_fields}->{actor} = 'VALUE';
    
    # 'trailer' stores an mpeg file, but CDBI::FB cannot automatically detect 
    # file upload fields, so need to tell it:
    Film->form_builder_defaults->{process_fields}->{trailer} = 'FILE';
    
    # has_a fields will be automatically set to 'required'. Additional fields can be specified:
    Film->form_builder_defaults->{required} = qw( foo bar );
    
    
    
    # In a nearby piece of code...
    
    my $film = Film->retrieve( $id ); 
    print $film->as_form( params => $q )->render;   # or $r if mod_perl
    
    # For a search app:    
    my $search_form = Film->search_form;            # as_form plus a few tweaks
    
    
    # A fairly complete mini-app:
    
    my $form = Film->as_form( params => $q );       # or $r if mod_perl
    
    if ( $form->submitted and $form->validate )
    {
        # whatever you need:
        
        my $obj = Film->create_from_form( $form );
        my $obj = Film->update_from_form( $form );              
        my $obj = Film->update_or_create_from_form( $form );    
        my $obj = Film->retrieve_from_form( $form );
        
        my $iter = Film->search_from_form( $form );
        my $iter = Film->search_like_from_form( $form );
        my $iter = Film->search_where_from_form( $form );
        
        my $obj = Film->find_or_create_from_form( $form );
        my $obj = Film->retrieve_or_create_from_form( $form );
        
        print $form->confirm;
    }
    else
    {
        print $form->render;
    }
    
    # See CGI::FormBuilder docs and website for lots more information.
    
=head1 DESCRIPTION

B<Errata: use of column name/accessor/mutator is currently broken if your column 
accessors/mutators are different from the column name>. The documentation is also broken w.r.t. this. 

This module creates a L<CGI::FormBuilder|CGI::FormBuilder> form from a CDBI class or object. If 
from an object, it populates the form fields with the object's values. 

Column metadata and CDBI relationships are analyzed and the fields of the form are modified accordingly. 
For instance, MySQL C<enum> and C<set> columns are configured as C<select>, C<radiobutton> or 
C<checkbox> widgets as appropriate, and appropriate widgets are built for C<has_a>, C<has_many> 
and C<might_have> relationships. Further relationships can be added by subclassing. C<has_a> columns 
are set as 'required' fields in create/update forms.

A demonstration app (using L<Maypole::FormBuilder|Maypole::FormBuilder>) can be viewed at 

    http://beerfb.riverside-cms.co.uk
    
=head1 Customising field construction

Often, the default behaviour will be unsuitable. For instance, a C<has_a> relationship might point to 
a related table with thousands of records. A popup widget with all these records is probably not useful.  
Also, it will take a long time to build, so post-processing the form to re-design the field is a 
poor solution. 

Instead, you can pass an extra C<process_fields> argument in the call to C<as_form> (or you can 
set it in C<form_builder_defaults>).

Many of the internal routines use this mechanism for configuring fields. A manually set '+' 
(basic) processor will be B<added> to any other automatic processing, whereas a manually set shortcut 
processor (no '+') will B<replace> all automatic processing. 

You can add your own processors to the internal table of processors - see C<new_field_processor>.

=head2 process_fields

This is a hashref, with keys being field names. Values can be:

=over 4

=item Name of a built-in

    basic             shortcut
    -------------------------------------------------------------------------------
    +HIDDEN           HIDDEN            make the field hidden
    +VALUE            VALUE             display the current value
    +READONLY         READONLY          display the current value - not editable
    +DISABLED         DISABLED          display the current value - not editable, not selectable, (not submitted?)
    +FILE             FILE              build a file upload widget
    +OPTIONS_FROM_DB  OPTIONS_FROM_DB   check if the column is constrained to a few values
    +REQUIRED                           make the field required
    +NULL                               no-op - useful for debugging
    +ADD_FIELD                          add a new field to the form (only necessary if the field is empty)
                      TIMESTAMP         used to process TIMESTAMP fields, defaults to DISABLED, but you can 
                                            easily replace it with a different behaviour
    +SET_VALUE($value)                  set the value of the field to $value - DEPRECATED - use +SET_value
    +SET_$foo($value) SET_$foo($value)  set the $foo attribute of the field to $value 
    
The 'basic' versions apply only their own modification. The 'shortcut' version also applies 
the C<+VALUE> processor. 
    
C<OPTIONS_FROM_DB> currently only supports MySQL ENUM or SET columns. You probably won't need to use 
this explicitly, as it's already used internally. 

The C<+ADD_FIELD> processor is only necessary if you need to add a new field to a form, but don't want to 
use any of the other processors on it. 

=item Reference to a subroutine, or anonymous coderef

The coderef will be passed the L<Class::DBI::FormBuilder> class or subclass, the CDBI class or 
object, the L<CGI::FormBuilder> form object, and the field name as arguments, and should build the 
named field. 

=item Package name 

Name of a package with a suitable C<field> subroutine. Gets called with the same arguments as 
the coderef.

=item Arrayref of the above

Applies each processor in order. 

=back

The key C<__FINAL__> is reserved for C<form_final>, so don't name any form fields C<__FINAL__>. If a 
field processor is set in C<__FINAL__>, then it will be applied to all fields, after all other 
processors have run. 

=head1 Customising C<render> output

C<Class::DBI::FormBuilder> replaces C<CGI::FormBuilder::render()> with a hookable version of C<render()>.
The hook is a coderef, or the name of a built-in, supplied in the C<post_process> argument (which can 
be set in the call to C<as_form>, C<search_form>, C<render>, or in C<form_builder_defaults>). The coderef 
is passed the following arguments:

    $class      the CDBI::FormBuilder class or subclass
    $form       the CGI::FormBuilder form object
    $render     reference to &CGI::FormBuilder::render
    $pp_args    value of the post_process_args argument, or undef
    %args       the arguments used in the CGI::FormBuilder->new call

The coderef should return HTML markup for the form, probably by calling C<< $render->( $form, %args ) >>. 

=over 4

=item PrettyPrint

A pretty-printer coderef is available in the hashref of built-in post-processors: 

    my $pretty = Class::DBI::FormBuilder->post_processors->{PrettyPrint};
    
So you can turn on pretty printing for a class by setting:

    My::Class->form_builder_defaults->{post_process} = Class::DBI::FormBuilder->post_processors->{PrettyPrint};
    
=item NoTextAreas

This post-processor ensures that any fields configured as C<textarea>s are converted to a plain C<text> 
field before rendering. 

This might have been used for instance in the L<Maypole::FormBuilder> editable 
C<list> template, to ensure each form in the table fits neatly into a single row. Except that method is 
an ugly hack that doesn't support post-processors.

=back
    
=head1 Plugins

C<has_a> relationships can refer to non-CDBI classes. In this case, C<form_has_a> will attempt to 
load (via C<require>) an appropriate plugin. For instance, for a C<Time::Piece> column, it will attempt 
to load L<Class::DBI::FormBuilder::Plugin::Time::Piece>. Then it will call the C<field> method in the plugin, 
passing the CDBI class for whom the form has been constructed, the form, and a L<Class::DBI::Column> object 
representing the field being processed. The plugin can use this information to modify the form, perhaps 
adding extra fields, or controlling stringification, or setting up custom validation. Note that the name of 
the form field should be retrieved from the field object as C<< $field->name >>, rather than relying 
on C< $field > to stringify itself, because it will stringify to C<< $field->name_lc >>.

If no plugin is found, a fatal exception is thrown. If you have a situation where it would be useful to 
simply stringify the object instead, let me know and I'll make this configurable.

=head1 Automatic validation setup

If you place a normal L<CGI::FormBuilder|CGI::FormBuilder> validation spec in the C<validate> argument,
that spec will be used to configure validation. 

If there is no spec in the method call or in C<< $class->form_builder_defaults->{validate} >>, then 
validation will be configured automatically. The default configuration is pretty basic, but you can modify it 
by placing settings in the C<auto_validate> argument, or in C<< $class->form_builder_defaults->{auto_validate} >>. 

=head2 Basic auto-validation

Given no validation options for a column in the C<auto_validate> slot, the settings for most columns 
will be taken from C<%Class::DBI::FormBuilder::ValidMap>. This maps SQL column types to the L<CGI::FormBuilder|CGI::FormBuilder> validation settings C<VALUE>, C<INT>, or C<NUM>. 

MySQL C<ENUM> or C<SET> columns will be set up to validate that the submitted value(s) match the allowed 
values. 

Any column listed in C<< $class->form_builder_defaults->{options} >> will be set to validate those values. 

=head2 Advanced auto-validation

The following settings can be placed in the C<auto_validate> argument (or in 
C<< $class->form_builder_defaults->{auto_validate} >>).

=over 4

=item validate

Specify validate types for specific columns:

    validate => { username   => [qw(nate jim bob)],
                  first_name => '/^\w+$/',    # note the 
                  last_name  => '/^\w+$/',    # single quotes!
                  email      => 'EMAIL',
                  password   => \&check_password,
                  confirm_password => {
                      javascript => '== form.password.value',
                      perl       => 'eq $form->field("password")'
                  }
                          
This option takes the same settings as the C<validate> option to C<CGI::FormBuilder::new()> 
(i.e. the same as would otherwise go in the C<validate> argument or in 
C<< $class->form_builder_defaults->{validate} >>). Settings here override any others. 

=item columns

Alias for C<validate>. Don't use both, they're not intended to be merged. Use whichever 
feels more comfortable. If you're used to using L<CGI::FormBuilder>, it may feel more 
natural to use C<validate>. If not, it may make more sense to use C<columns>.

=item skip_columns

List of columns that will not be validated:

    skip_columns => [ qw( secret_stuff internal_data ) ]

=item match_columns

Use regular expressions matching groups of columns to specify validation:

    match_columns => { qr/(^(widget|burger)_size$/ => [ qw( small medium large ) ],
                       qr/^count_.+$/             => 'INT',
                       }
                       
=item validate_types

Validate according to SQL data types:

    validate_types => { date => \&my_date_checker,
                        }
                       
Defaults are taken from the package global C<%TypesMap>. 
                        
=item match_types

Use a regular expression to map SQL data types to validation types:

    match_types => { qr(date) => \&my_date_checker,
                     }
                     
=item debug
    
Control how much detail to report (via C<warn>) during setup. Set to 1 for brief 
info, and 2 for a list of each column's validation setting.

=item strict

If set to 1, will die if a validation setting cannot be determined for any column. 
Default is to issue warnings and not validate these column(s).

=back
    
=head2 Validating relationships

Although it would be possible to retrieve the IDs of all objects for a related column and use these to 
set up validation, this would rapidly become unwieldy for larger tables. Default validation will probably be 
acceptable in most cases, as the column type will usually be some kind of integer. 

=over 4

=item timestamp

The default behaviour is to skip validating C<timestamp> columns. A warning will be issued
if the C<debug> parameter is set to 2.

Note that C<timestamp> columns are rendered as C<readonly> (see C<form_timestamp>). 

=item Failures

The default mapping of column types to validation types is set in C<%Class::DBI::FormBulder::ValidMap>, 
and is probably incomplete. If you come across any failures, you can add suitable entries to the hash before calling C<as_form>. However, B<please> email me with any failures so the hash can be updated for everyone.

=back

=cut

=head1 Other features

=over 4

=item Class::DBI::FromForm

If you want to use this module alongside L<Class::DBI::FromForm|Class::DBI::FromForm>, 
load the module like so

    use Class::DBI::FormBuilder BePoliteToFromForm => 1;
    
and C<create_from_form> and C<update_from_form> will instead be imported as C<create_from_fb> and C<update_from_fb>.

You might want to do this if you have more complex validation requirements than L<CGI::FormBuilder|CGI::FormBuilder> provides. 
    
=back

=head1 METHODS

Most of the methods described here are exported into the caller's namespace, except for the form modifiers 
(see below), and a few others as documented. 

=over 4

=item new_field_processor( $processor_name, $coderef or package name )

This method is called on C<Class::DBI::FormBuilder> or a subclass, rather than on a L<Class::DBI> 
object or subclass. 

It installs a new field processor, which can then be referred to by name in C<process_fields>, 
rather than by passing a coderef. This method could also be used to replace the supplied built-in 
field processors, for example to alter the default C<TIMESTAMP> behaviour (see C<form_timestamp>). 
The new processor must either be a coderef, or the name of a package with a 
suitable C<field> method, or the name of another processor, or an arrayref of any of these.

The code ref will be passed these arguments: 

    position    argument
    --------------------
       0        name of the calling class (i.e. Class::DBI::FormBuilder or a subclass)
       1        Class::DBI object or class name
       2        CGI::FormBuilder form object
       3        name of the current field
       4        Class::DBI::Column object for the current field
     
The name of the current field is the name used on the form object, and is also the B<mutator> accessor 
for the column on the CDBI object (which defaults to the name in the database, but can be different). 

The column object is useful if the processor needs access to the value in the CDBI object, but the 
mutator name is different from the column accessor e.g. see the C<+VALUE> processor.
       
=cut   
    
# ----------------------------------------------------------------- field processor architecture -----

# install a new default processor that can be referred to by name
sub new_field_processor
{
    my ( $me, $p_name, $p ) = @_;
    
    my $coderef = $p if ref( $p ) eq 'CODE';
    
    unless ( $coderef )
    {
        $p->require || die "Error loading custom field processor package $p: $@";
        
        UNIVERSAL::can( $p, 'field' ) or die "$p does not have a field() subroutine";
        
        no strict 'refs';
        $coderef = \&{"$p\::field"};    
    }
    
    $me->field_processors->{ $p_name } = $coderef;    
}

# use a chain of processors to construct a field
sub _process_field
{
    my ( $me, $them, $form, $field, $process ) = @_;
    
    # $field will normally be a CDBI column object, but can be a string
    #my $field_name = ref $field ? $field->mutator : $field;
    my $field_name = ref $field ? $field->name : $field;
    
    # some processors (e.g. +VALUE) need access to accessor name, not mutator name
    #my $column = ref $field ? $field : $me->_column_from_mutator( $them, $field );
    my $column = ref $field ? $field : $them->find_column( $field );
    
    my $chain = $me->_build_processor_chain( $process );
    
    # pass the form to each sub in the chain and tweak the specified field
    while ( my $p = $chain->() )
    {
        $p->( $me, $them, $form, $field_name, $column );
    }
}

# returns an iterator
sub _build_processor_chain
{
    my ( $me, $process ) = @_;
    
    my @agenda = ( $process );
    
    # Expand each item on the agenda. Arrayrefs get listified and unshifted back 
    # on to the start of the agenda. Coderefs on the agenda are returned. Non-code scalars are 
    # looked up in the pre-processors dispatch table, or in another package, and 
    # unshifted onto the start of the agenda, because they may be pointing to 
    # further keys in the dispatch table. 
    my $chain;
    
    $chain = sub
    {
        my $next = pop( @agenda );
        
        return unless $next;
        
        return $next if ref( $next ) eq 'CODE';
        
        unshift @agenda, ref $next eq 'ARRAY' ? @$next : $me->_track_down( $next );
        
        return $chain->();    
    };
    
    return $chain;
}

sub _track_down
{
    my ( $me, $processor ) = @_;
    
    return $processor if ref( $processor ) eq 'CODE';
    
    my $p = $me->field_processors->{ $processor };
    
    # might be a coderef, might be another key
    return $p if $p;
    
    # +SET_VALUE() special case - DEPRECATED in 0.41
    if ( $processor =~ /^\+SET_VALUE\(\s*(.*)\s*\)$/ )
    {
        my $value = $1;
        
        warn '+SET_VALUE($value) is deprecated - use +SET_value($value) instead';
        
        $p = sub { $_[FORM]->field( name  => $_[FIELD],
                                    value => $value,   
                                    );
                 };
                 
        return $p;
    }          
    
    # +SET_$foo($bar) general special case
    if ( $processor =~ /^(?:\+?)SET_(\w+)\(\s*(.*)\s*\)$/ )
    {
        my $attribute = $1;
        my $value     = $2;
        
        $p = sub { $_[FORM]->field( name       => $_[FIELD],
                                    $attribute => $value,
                                    );
                   };
         
        return $p;
    }       
    
#    # +FIELD_PREFIX($prefix)
#    if ( $processor =~ /^\+FIELD_PREFIX(\s*(.*)\s*\)$/ )
#    {
#        my $prefix = $1;
#        
#        $p = sub { $_[FORM]->field( name => $_[FIELD],
#    
#    }
    
    die "Unexpected ref: $processor (expected class name)" if ref $processor;
    
    # it's a field sub in another class
    $processor->require or die "Couldn't load field processor package $processor: $@";
    
    $p = $processor->can( 'field' ) || die "No field method in $processor";
    
    return $p;
}

# Combines automatic and custom processors. Custom processors are 
# traversed until a 'stop' processor is found (a named processor without a leading '+'). 
# If found, returns the custom set only. If no 'stop' processor is found, appends the 
# custom set to the auto set. 
sub _add_processors
{
    my ( $me, $field, $pre_process, $auto ) = @_;
    
    # $field will usually be a CDBI column object
    my $field_name = ref $field ? $field->mutator : $field;
    
    my $custom = $pre_process->{ $field_name };
    
    #warn sprintf "Combining procs %s and %s\n", $auto || '', $custom || '';
    
    # I'd use xor if I had a one-liner that doesn't use the temp var
    #my $only = $custom xor $auto;
    #return $only if $only; 
    return $custom unless $auto;
    return $auto   unless $custom;
    
    my $chain = $me->_build_named_processor_chain( $custom );
    
    while ( my $name = $chain->() )
    {
        #warn "Checking custom processor $name for stop";
        #warn "Dropping automatic processors - found custom stop processor $name" if $name !~ /^\+/;
        return $custom if $name !~ /^\+/;
    }
    
    return [ $auto, $custom ]; # it's OK if either are already arrayrefs
}

# only use this to look at the names, not to do any processing, because it throws away 
# any processors that are not named
sub _build_named_processor_chain
{
    my ( $me, $process ) = @_;
    
    my @agenda = ( $process );
    
    # Expand each item on the agenda. Arrayrefs get listified and unshifted back 
    # on to the start of the agenda. Coderefs on the agenda are returned. Non-code scalars are 
    # looked up in the pre-processors dispatch table, or in another package, and 
    # unshifted onto the start of the agenda, because they may be pointing to 
    # further keys in the dispatch table. 
    my $chain;
    
    $chain = sub
    {
        my $next = pop( @agenda );
        
        return unless $next;
        
        # if it's a coderef, drop it and move on to next item
        return $chain->() if ref( $next ) eq 'CODE'; 
        
        # if it's an arrayref, expand it onto the start of the agenda and move on 
        # to next item (i.e. first item in the arrayref)
        if ( ref( $next ) eq 'ARRAY' )
        {
            unshift @agenda, @$next;
            return $chain->();
        }
        
        die "Unexpected ref for processor: $next" if ref $next;
        
        # It's a string
        # if it's in the processors hash, then
        #   - check if it returns a coderef or an arrayref or a string when looked up
        #       - if a coderef, return the string
        #       - unshift anything else onto the agenda
        if ( my $foo = $me->field_processors->{ $next } )
        {
            return $next if ref $foo eq 'CODE';
            
            # it's a string or an arrayref
            unshift @agenda, $foo;
        }
        
        return $chain->();
    };
    
    return $chain;
}

# ----------------------------------------------------------------- / field processor architecture -----

# ----------------------------------------------------------------------- column meta data -----

=item table_meta($them)

L<Class::DBI::FormBuilder> class method.

Returns a L<Class::DBI::FormBuilder::Meta::Table> object.

=cut

sub table_meta
{
    my ($me, $them) = @_;
    
    return Class::DBI::FormBuilder::Meta::Table->instance($them);
}

# Return the class or object(s) associated with a field, if anything is associated. 
# This can't go in table_meta because it can be called on objects (???)
sub _related
{
    my ($me, $them, $field) = @_;
    
    my ($related_class, $rel_type) = $me->table_meta($them)->related_class_and_rel_type($field);
    
    return unless $related_class;
    
    return ($related_class, $rel_type) unless ref $them;
    
    my $related_meta = $them->meta_info( $rel_type => $field ) ||
            die "No '$rel_type' meta for '$them', field '$field'";
    
    my $accessor = eval { $related_meta->accessor };    
    die "Error retrieving accessor in meta '$related_meta' for '$rel_type' field '$field' in '$them': $@" if $@;
    
    # multiple objects for has_many
    my @related_objects = $them->$accessor;
    
    return ( $related_class,      $rel_type ) unless @related_objects;
    return ( $related_objects[0], $rel_type ) if @related_objects == 1; 
    return ( \@related_objects,   $rel_type );
}

# ----------------------------------------------------------------------- / column meta data -----

=back

=head2 Form generating methods

=over 4

=item form_builder_defaults( %args )

Stores default arguments.  

=item as_form( %args )

Builds a L<CGI::FormBuilder|CGI::FormBuilder> form representing the class or object. 

Takes default arguments from C<form_builder_defaults>. 

The optional hash of arguments is the same as for C<CGI::FormBuilder::new()>, with a few extras, 
and will override any keys in C<form_builder_defaults>. 

The extra keys are documented in various places in this file - I'll gather them together here 
over time. Extra keys include:

=over 4

=item options_sorters

A hashref, keyed by field name, with values being coderefs that will be used to sort the list 
of options generated for a C<has_a>, C<has_many>, or C<might_have> field. 

The coderef will be passed pairs of options arrayrefs, and should return the standard Perl sort 
codes (i.e. -1, 0, or 1). The first item in each arrayref is the value of the option, the second 
is the label.

Note that the coderef should be prototyped ($$):

    # sort by label, alphabetically
    $field_name => sub ($$) { $_[0]->[1] cmp $_[1]->[1] }

    # sort by value, numerically
    $field_name => sub ($$) { $_[0]->[0] <=> $_[1]->[0] }

=back

Note that parameter merging is likely to become more sophisticated in future releases 
(probably copying the argument merging code from L<CGI::FormBuilder|CGI::FormBuilder> 
itself).

=item search_form( %args )

Build a form with inputs that can be fed to search methods (e.g. C<search_where_from_form>). 
For instance, all selects are multiple, fields that normally would be required 
are not, and C<TEXT> columns are represented as C<text> fields rather than as C<textarea>s by default.

B<Automatic configuration of validation settings is not carried out on search forms>. You can 
still configure validation settings using the standard L<CGI::FormBuilder> settings. 

In many cases, you will want to design your own search form, perhaps only searching 
on a subset of the available columns. Note that you can acheive that by specifying 

    fields => [ qw( only these fields ) ]
    
in the args. 

The following search options are available. They are only relevant if processing 
via C<search_where_from_form>.

=over 4

=item search_opt_cmp

Allow the user to select a comparison operator by passing an arrayref:

    search_opt_cmp => [ ( '=', '!=', '<', '<=', '>', '>=', 
                          'LIKE', 'NOT LIKE', 'REGEXP', 'NOT REGEXP',
                          'REGEXP BINARY', 'NOT REGEXP BINARY',
                          ) ]
    

Or, transparently set the search operator in a hidden field:

    search_opt_cmp => 'LIKE'
    
=item search_opt_order_by

If true, will generate a widget to select (possibly multiple) columns to order the results by, 
with an C<ASC> and C<DESC> option for each column.

If set to an arrayref, will use that to build the widget. 

    # order by any columns
    search_opt_order_by => 1
    
    # or just offer a few
    search_opt_order_by => [ 'foo', 'foo DESC', 'bar' ]
    
=back

=cut

sub as_form
{
    my ( $them, %args_in ) = @_;
    
    my $me = $them->__form_builder_subclass__;
    
    return scalar $me->_as_form( $them, %args_in );    
}

=begin notes

There seem to be several ways to approach this:

1. Modify the original args, so that CGI::FB builds a single form with multiple sets of inputs. 
    This seems difficult, but would result in a form that could be processed very easily.
    
2. Build multiple forms, and use a custom javascript submit button to gather all their inputs and 
    submit a single form. The js is tricky, and processing the input is not easy, because we don't 
    have a server form to handle it.
    
3. Use HTML::Tree to build a super-form from a standard form. Same problem with processing input as 
    for #2.
    
4. AJAX - instead of submitting all forms in one go (as in #2), submit each form individually. This 
    would solve the problem of processing the submission, but requires a different architecture.  

Seems to boil down to #1 or #3. 

The problem with #1 is that after building the CGI::FB form, it is then passed through all the form 
modifiers, including any registered field processors. All of this would have to cope with modifying 
field names. But maybe that could be done via a final field modifier?

The problem with #3 is processing submissions, since the final form is never represented by a CGI::FB
form. 

UPDATE: the solution is:

5. Build the individual forms, tweak their field names, then combine all the fields
    from all the forms into a single form. This works because most of the CGI::FB magic 
    does not happen during form construction, but during calls made on the completed form.
    
=end notes

=cut

=item as_multiform

This method supports adding multiple related items to an object in a related class. Call this method 
on the class at the 'many' end of a C<has_many> relationship. Instead of building a form with fields 

    foo 
    bar
    baz
    
it builds a form with fields

    R1__foo
    R1__bar
    R1__baz
    R2__foo
    R2__bar
    R2__baz
    etc.
    
Specify the number of duplicates in the C<how_many> required argument.

Use C<create_from_multiform> to process a form submission.
    
See C<Maypole::FormBuilder::Model::addmany()> and the C<addmany> template for example usage. 

=cut

sub as_multiform
{
    my ( $them, %args_in ) = @_;
    
    my $me = $them->__form_builder_subclass__;
    
    my $how_many = delete $args_in{how_many} || die 'need to know how many to build';
    
    my @forms;
    
    foreach my $fnum ( 1..$how_many )
    {
        my $prefix = "R$fnum\__";
        my $form = $them->as_form( %args_in );
        
        my @fields = $form->fields;
        
        foreach my $field ( @fields )
        {
            # get the label before it changes
            my $label = $field->label;
            my $name  = $field->name;
            $field->name( "$prefix${name}" );
            # put the label back
            $field->label( $label );
        }
        
        # put a bit of space after the last field
        $fields[-1]->comment( '<br />&nbsp;' );
        
        push @forms, $form;
    }
     
    return $me->_merge_forms( @forms );   
}

sub _merge_forms
{
    my ( $me, @forms ) = @_;
    
    my $form = shift @forms;
    
    foreach my $additional_form ( @forms )
    {
        foreach my $field ( $additional_form->fields )
        {
            $field->_form( $form );
            
            $form->{fieldrefs}{ $field->name } = $field;
        
            push @{ $form->{fields} }, $field;
        }
    }
    
    return $form;
}

sub _as_form
{
    my ( $me, $them, %args_in ) = @_;
    
    # search_form does not (automatically) validate input
    my $skip_validation = delete $args_in{__SKIP_VALIDATION__};
    
    my ( $orig, %args ) = $me->_get_args( $them, %args_in );
    
    $me->_setup_auto_validation( $them, \%args ) unless $skip_validation;
    
    my $form = $me->_make_form( $them, $orig, %args );
    
    return wantarray ? ( $form, %args ) : $form;
}

sub search_form
{
    my ( $them, %args_in ) = @_;
    
    my $me = $them->__form_builder_subclass__;
    
    my $cdbi_class = ref( $them ) || $them;
    
    $args_in{__SKIP_VALIDATION__}++;
    
    my ( $form, %args ) = $me->_as_form( $cdbi_class, %args_in );
    
    # We need the names of two special fields and a regexp to recognize them
    my $order_by_field_name = 'search_opt_order_by';
    my $cmp_field_name      = 'search_opt_cmp';
    my $regexp = qr/^(?:$order_by_field_name|$cmp_field_name)$/o;    
    
    # make all selects multiple, no fields required unless explicitly set, 
    # and change textareas back into text inputs
    my %force_required = map { $_ => 1 } @{ $args{required} || [] };
    foreach my $field ( $form->field )
    {
        next unless exists $form->field->{ $field }; 
        
        # skip search controls 
        next if $field =~ $regexp;
        
        $field->multiple( 1 ) if $field->options;
                      
        $field->required( 0 ) unless $force_required{ $field };
        
        $field->type( 'text' ) if $field->type eq 'textarea';
        
        # some default field processors may set a value, which needs to be 
        # removed on the search form
        #$field->value( undef ); # this requires CGI::FB 3.03
        $form->field( name => $field->name, value => undef );
    }   
    
    # ----- customise the search -----
    # For processing a submitted form, remember that the field _must_ be added to the form 
    # so that its submitted value can be extracted in search_where_from_form()
    
    # ----- order_by
    # this must come before adding any other fields, because the list of columns 
    # is taken from the form (not the CDBI class/object) so we match whatever 
    # column selection happened during form construction
    my %order_by_spec = ( # name     => 'search_opt_order_by',
                          multiple => 1,
                          );
    
    if ( my $order_by = delete $args{ $order_by_field_name } )
    {
        $order_by = [ map  { ''.$_, "$_ DESC" } 
                      grep { $_->type ne 'hidden' and $_ !~ $regexp } 
                      $form->field 
                      ] 
                      unless ref $order_by;
        
        $order_by_spec{options} = $order_by;
    }
    
    # ----- comparison operator    
    my $cmp = delete( $args{ $cmp_field_name } ) || '=';
    
    my %cmp_spec; # = ( name => 'search_opt_cmp' );
    
    if ( ref( $cmp ) )
    {
        $cmp_spec{options}  = $cmp;
        $cmp_spec{value}    = $cmp->[0];
        #$cmp_spec{multiple} = 0;
    }
    else
    {
        $cmp_spec{value} = $cmp;
        $cmp_spec{type}  = 'hidden';
    }
    
    # this is annoying...
    my %fields = map { ''.$_ => $_ } $form->field;
    
    # if the caller has passed in some custom settings, they will have caused the field to be 
    # auto-vivified
    if ( my $cmp_field = $fields{ $cmp_field_name } )
    {
        # this (used to?) causes a warning when setting the value, which may mean the value has already been set before
        $cmp_field->$_( $cmp_spec{ $_ } ) for keys %cmp_spec;    
    }
    else
    # otherwise, we need to auto-vivify it now
    {
        $form->field( name => $cmp_field_name, %cmp_spec );    
    }
    
    if ( my $order_by_field = $fields{ $order_by_field_name } )
    {
        $order_by_field->$_( $order_by_spec{ $_ } ) for keys %order_by_spec;   
    }
    else
    {
        $form->field( name => $order_by_field_name, %order_by_spec );    
    }
    
    # ...why did this stop working? - I think because sometimes the fields are auto-vivified before getting 
    # to this point, and that seems to be problem when setting the value
    #$form->field( %cmp_spec );    
    #$form->field( %order_by_spec );    
    
    return $form;
}

# need to do much better argument merging
sub _get_args
{
    my ( $me, $them, %args_in ) = @_;
    
    #@{ $args_in{fields} } = map { ''.$_ } @{ $args_in{fields} } if $args_in{fields};
    
    # NOTE: this merging still means any custom processors for a given field, will replace all default 
    #           processors for that field, but at least we can mix some fields having default 
    #           processors, and others having custom ones.
    my $pre_process1 = $them->form_builder_defaults->{process_fields} || {};
    my $pre_process2 = delete( $args_in{process_fields} ) || {};
    my %pre_process  = ( %$pre_process1, %$pre_process2 );
    
    # merge sorters and remove from %args_in (although note that any default sorters will still 
    # be present in %args)
    my %options_sorters = ( %{ $them->form_builder_defaults->{options_sorters} || {} }, 
                            %{ delete( $args_in{options_sorters} ) || {} },
                            );
    
    my %args = ( %{ $them->form_builder_defaults }, %args_in );
    
    $args{process_fields} = \%pre_process;
    
    # take a copy, and make sure not to transform undef into []
    my $original_fields = $args{fields} ? [ @{ $args{fields} } ] : undef;
    
    my %pk = map { $_ => $_ } $them->primary_columns;
    
    $args{fields} ||= [ grep { ! $pk{ $_ } } $me->table_meta( $them )->columns( 'All' ) ];
    
    # convert anything referring to a column, into a CDBI column object
    $args{fields} = [ map { ref $_ ? $_ : $them->find_column( $_ ) || $_ } @{ $args{fields} } ];
                        
    push( @{ $args{keepextras} }, values %pk ) unless ( $args{keepextras} && $args{keepextras} == 1 );
    
    # for objects, populate with data
    if ( ref $them )
    {
        # nb. can't simply say $proto->get( $_ ) because $_ may be an accessor installed by a relationship 
        # (e.g. has_many) - get() only works with real columns. 
        # Note that has_many and might_have and has_a fields are re-processed later (in form_* methods), 
        # it might become necessary to filter them out here?
        my @values = eval { map { $them->$_ }  # may return a scalar, undef, or object (or objects for has_many?)
                            map { ref $_ ? $_->accessor : $_ }
                            @{ $args{fields} } # may be strings or CDBI column objects
                            };
        
        die "Error populating values for $them from '@{ $args{fields} }': $@" if $@;
    
        $args{values} ||= \@values;
    }
    
    my %post_process = ( 
        post_process      => delete( $args_in{post_process} )      || $them->form_builder_defaults->{post_process},
        post_process_args => delete( $args_in{post_process_args} ) || $them->form_builder_defaults->{post_process_args},
                         );
                         
    %post_process = () unless $post_process{post_process};
    
    my $process_extras = delete( $args_in{process_extras} ) || [];
    
    # store a few CDBI::FB arguments that may be needed later
    my $orig = { fields => $original_fields,
                 %post_process,
                 process_extras => $process_extras,
                 options_sorters => \%options_sorters,
                 };
    
    return $orig, %args;
}

sub _make_form
{
    my ($me, $them, $orig, %args) = @_;
    
    my $pre_process = delete( $args{process_fields} ) || {};
    
    my %clean_args = $me->_stringify_args(%args);
    
    my $form = CGI::FormBuilder->new(%clean_args);
    
    $form->{__cdbi_original_args__} = $orig;
    
    # this assumes meta_info only holds data on relationships
    foreach my $modify ( @BASIC_FORM_MODIFIERS, keys %{ $them->meta_info } ) 
    {
        my $form_modify = "form_$modify";
        
        $me->$form_modify($them, $form, $pre_process);
    }
    
    return $form;
}

# If any columns are supplied as CDBI column objects, we need to change them into the appropriate 
# string, which is supplied by the mutator method on the column. 
# Also, CGI::FB does some argument pre-processing that chokes on objects, even if the objects can be 
# stringified, so values need to be stringified here. 
sub _stringify_args
{
    my ( $me, %args ) = @_;
    
    #warn "Dirty args: " . Dumper( \%args );

    # fields - but this could also be a hashref?
    @{ $args{fields} } = map { ref $_ ? $_->mutator : $_ } @{ $args{fields} };
    
    # keepextras
    @{ $args{keepextras} } = map { ref $_ ? $_->mutator : $_ } @{ $args{keepextras} };
    
    
    # values
    @{ $args{values} } = map { defined $_ ? ''.$_ : undef } @{ $args{values} };
    
    
    # validate
    
    
    # auto_validate is still in here - needs to be removed
    
    
    #warn "Clean args: " . Dumper( \%args );
    return %args;
}

=item as_form_with_related

B<DEPRECATED>.

B<This method is NOT WORKING, and will be removed from a future version>. The plan is to replace C<as_form> 
with this code, when it's working properly. 

Builds a form with fields from the target CDBI class/object, plus fields from the related objects. 

Accepts the same arguments as C<as_form>, with these additions:

=over 4

=item related

A hashref of C<< $field_name => $as_form_args_hashref >> settings. Each C<$as_form_args_hashref> 
can take all the same settings as C<as_form>. These are used for generating the fields of the class or 
object(s) referred to by that field. For instance, you could use this to only display a subset of the 
fields of the related class. 

=item show_related

By default, all related fields are shown in the form. To only expand selected related fields, list 
them in C<show_related>.

=back

=cut

sub as_form_with_related
{
    my ( $proto, %args ) = @_;
    
    my $cdbifb = $proto->__form_builder_subclass__;
    
    my $related_args = delete( $args{related} );
    my $show_related = delete( $args{show_related} ) || [];
    
    my $parent_form = $proto->as_form( %args );
    
    foreach my $field ( $cdbifb->_fields_and_has_many_accessors( $proto, $parent_form, $show_related ) )
    {
        # object or class
        my ( $related, $rel_type ) = $cdbifb->_related( $proto, $field );
        
        next unless $related;
        
        my @relateds = ref( $related ) eq 'ARRAY' ? @$related : ( $related );
        
        $cdbifb->_splice_form( $_, $parent_form, $field, $related_args->{ $field }, $rel_type ) for @relateds;
    }
    
    return $parent_form;
}

# deliberately ugly name to encourage something more generic in future
sub _fields_and_has_many_accessors
{
    my ( $me, $them, $form, $show_related ) = @_;
    
    return @$show_related if @$show_related;
    
    # Cleaning these out appears not to fix multiple pc fields, but also seems like the 
    # right thing to do. 
    my %pc = map { $_ => 1 } $them->primary_columns;
    
    my @fields = grep { ! $pc{ $_ } } $form->field;
    
    my %seen = map { $_ => 1 } @fields;
    
    my @related = keys %{ $them->meta_info( 'has_many' ) || {} };
    
    push @fields, grep { ! $seen{ $_ } } @related;
    
    return @fields;
}
        
# Add fields representing related class/object $them, to $parent_form, which represents 
# the class/object as_form_with_related was called on. E.g. add brewery, style, and many pubs 
# to a beer form. 
sub _splice_form
{
    my ( $me, $them, $parent_form, $field_name, $args, $rel_type ) = @_;
    
    # related pkdata are encoded in the fake field name
    warn 'not sure if pk for related objects is getting added - if so, it should not';
    
    #warn "need to add 'add relatives' button"; - see Maypole edit template now
    return unless ref $them; # for now
    
    my $related_form = $them->as_form( %$args );
    
    my $moniker = $them->moniker;
    
    my @related_fields;
    
    foreach my $related_field ( $related_form->fields )
    {
        my $related_field_name = $related_field->name; # XXX mutator
        
        my $fake_name = $me->_false_related_field_name( $them, $related_field_name );
        
        $related_field->_form( $parent_form );
        
        $related_field->name( $fake_name );  
        
        $related_field->label( ucfirst( $moniker ) . ': ' . $related_field_name ) 
            unless $args->{labels}{ $related_field_name };
        
        $parent_form->{fieldrefs}{ $fake_name } = $related_field;
    
        push @related_fields, $related_field;
    }

    my $offset = 0;
    
    foreach my $parent_field ( $parent_form->fields )
    {
        $offset++;
        last if $parent_field->name eq $field_name;        
    }
    
    splice @{ $parent_form->{fields} }, $offset, 0, @related_fields;

    # different rel_types get treated differently e.g. is_a should probably not 
    # allow editing
    if ( $rel_type eq 'has_a' )
    {
        $parent_form->field( name => $field_name,
                             type => 'hidden',
                             );
    }
    elsif ( $rel_type eq 'is_a' )
    {
        $parent_form->field( name     => ''.$_,
                             readonly => 1,
                             )
                                for @related_fields;
    }
    
}


# ------------------------------------------------------- encode / decode field names -----
sub _false_related_field_name
{
    my ( $me, $them, $real_field_name ) = @_;
    
    my $class = $me->_encode_class( $them );
    my $pk    = $me->_encode_pk( $them );
    
    return $real_field_name . $class . $pk;
}

sub _real_related_field_name
{
    my ( $me, $field_name ) = @_;

    # remove any encoded class
    $field_name =~ s/CDBI_.+_CDBI//;
    
    # remove any primary keys
    $field_name =~ s/PKDATA_.+_PKDATA//;
    
    return $field_name;
}

sub _encode_pk
{
    my ( $me, $them ) = @_;
    
    return '' unless ref( $them );
    
    my @pk = map { $them->get( $_ ) } $them->primary_columns;
    
    die "dots in primary key values will confuse _encode_pk and _decode_pk"
        if grep { /\./ } @pk;
    
    my $pk = sprintf 'PKDATA_%s_PKDATA', join( '.', @pk );

    return $pk;
}

sub _decode_pk
{
    my ( $me, $fake_field_name ) = @_;
    
    return unless $fake_field_name =~ /PKDATA_(.+)_PKDATA/;
    
    my $pv = $1;
    
    my @pv = split /\./, $pv;
    
    my $class = $me->_decode_class( $fake_field_name );
    
    my @pc = map { ''.$_ } $class->primary_columns;
    
    my %pk = map { $_ => shift( @pv ) } @pc;
    
    return %pk;
}

sub _decode_class
{
    my ( $me, $fake_field_name ) = @_;

    $fake_field_name =~ /CDBI_(.+)_CDBI/;
    
    my $class = $1;
    
    $class || die "no class in fake field name $fake_field_name";
    
    $class =~ s/\./::/g;
    
    return $class;
}

sub _encode_class
{
    my ( $me, $them ) = @_;
    
    my $token = ref( $them ) || $them;
    
    $token =~ s/::/./g;
    
    return "CDBI_$token\_CDBI";   
}

sub _retrieve_entity_from_fake_fname
{
    my ( $me, $fake_field_name ) = @_;
    
    my $class = $me->_decode_class( $fake_field_name );
    
    my %pk = $me->_decode_pk( $fake_field_name );
    
    return $class unless %pk;
    
    my $obj = $class->retrieve( %pk );

    return $obj;
}

# ------------------------------------------------------- end encode / decode field names -----

=back

=head2 Form modifiers

These methods use CDBI's knowledge about its columns and table relationships to tweak the 
form to better represent a CDBI object or class. They can be overridden if you have better 
knowledge than CDBI does. For instance, C<form_options> only knows how to figure out 
select-type columns for MySQL databases. 

You can handle new relationship types by subclassing, and writing suitable C<form_*> methods (e.g. 
C<form_many_many)>. Your custom methods will be automatically called on the relevant fields. 

C<has_a> relationships to non-CDBI classes are handled via a plugin mechanism (see above). 

=over 4

=item form_hidden

Deprecated. Renamed C<form_pks>.

=item form_pks

Ensures primary column fields are included in the form (even if they were not included in the 
C<fields> list), and hides them. Only forms representing objects will have primary column fields added.

=cut

# these fields are not in the 'fields' list, but are in 'keepextras'
sub form_hidden { warn 'form_hidden is deprecated - use form_pks instead'; goto &form_pks }

sub form_pks
{
    my ( $me, $them, $form, $pre_process ) = @_;
    
    # don't add pk fields to class forms
    return unless ref $them;
    
    foreach my $field ( $them->primary_columns )
    {
        my $process = $me->_add_processors( $field, $pre_process, 'HIDDEN' ); 
        
        $me->_process_field( $them, $form, $field, $process );
    }
}

=item form_options

Identifies column types that should be represented as select, radiobutton or 
checkbox widgets. Currently only works for MySQL C<ENUM> and C<SET> columns. 

Patches are welcome for similar column types in other RDBMS's. 

Note that you can easily emulate a MySQL C<ENUM> column at the application level by setting 
the validation for the column to an arrayref of values. Emulate a C<SET> column by additionally 
setting the C<multiple> option to C<1>.

=cut

sub form_options
{
    my ( $me, $them, $form, $pre_process ) = @_;
    
    foreach my $field ( $them->columns('All') )
    {
        next unless exists $form->field->{ $field->mutator }; # $form->field( name => $field );
        
        # +OPTIONS_FROM_DB is a no-op if the db column isn't enum or set
        my $process = $me->_add_processors( $field, $pre_process, 'OPTIONS_FROM_DB' ); 
        
        $me->_process_field( $them, $form, $field, $process );
    }    
}

=item form_has_a

Populates a select-type widget with entries representing related objects. Makes the field 
required.

Note that this list will be very long if there are lots of rows in the related table. 
You may need to override this behaviour by setting up a pre-processor for your C<has_a> fields. See
'Customising field construction'.

This method assumes the primary key is a single column - patches welcome. 

Retrieves every row and creates an object for it - not good for large tables.

If the relationship is to a non-CDBI class, loads a plugin to handle the field (see 'Plugins').

=cut

sub form_has_a
{
    my ($me, $them, $form, $pre_process) = @_;
    
    my $meta = $them->meta_info('has_a') || return;
    
    my @haves = map { $them->find_column($_) } keys %$meta;
    
    foreach my $field (@haves) 
    {
        next unless exists $form->field->{ $field->mutator };
        
        # See Ron's bug report about inconsistent behaviour of processors. 
        # This will also affect form_has_many and form_might_have
        #warn "BUG: it's an error to stop processing the field just because a processor is defined";
        
        # if a custom field processor has been supplied, use that
        my $processor = $pre_process->{ $field->mutator };
        $me->_process_field($them, $form, $field, $processor) if $processor;
        next if $processor;        
        
        my ($related_class, undef) = $me->table_meta($them)->related_class_and_rel_type($field);
        
        my $nullable = $me->table_meta($them)->column($field)->is_nullable;
        
        if ( $related_class->isa('Class::DBI') ) 
        {
            my $options = $me->_field_options($them, $form, $field) || 
                die "No options detected for field '$field'";
                
            my ($related_object, $value);
            
            if (ref $them)
            {
                my $accessor = $field->accessor;
                $related_object = $them->$accessor;
                 
                if( ! defined $related_object and ! $nullable )
                {
                    die sprintf 
                        'Failed to retrieve a related object from %s has_a field %s - inconsistent db?',
                            ref $them, $accessor;
                }
                    
                my $pk = $related_object->primary_column if defined $related_object;
                    
                $value = $related_object->$pk if defined $related_object; 
            }
            
            my $required = $nullable ? 0 : 1;
                
            $form->field( name     => $field->mutator,
                          options  => $options,
                          required => $required,
                          value    => $value,
                          );        
        } 
        else 
        {
            my $class = "Class::DBI::FormBuilder::Plugin::$related_class";
                        
            # if the class is not in its own file, require will not find it, 
            # even if it has been loaded
            if ( eval { $class->can('field') } or $class->require )
            {
                $class->field($me, $them, $form, $field);
            }
#            elsif ( $@ =~ // ) XXX
#            {
#                # or simply stringify
#                $form->field( name     => $field,
#                              required => 1,
#                              value    => $them->$field.'',
#                              );        
#            }
            else
            {
                die "Failed to load $class: $@";
            }
        }        
        
    }
}

=item form_has_many 

Also assumes a single primary column.

=cut

sub form_has_many
{
    my ( $me, $them, $form, $pre_process ) = @_;
    
    my $meta = $them->meta_info( 'has_many' ) || return;
    
    my @has_many_fields = $me->_multiplicity_fields( $them, $form, 'has_many' );
    
    # The target class/object ($them) does not have a column for the related class, 
    # so we need to add these to the form, then figure out their options.
    # Need to make sure and set some attribute to create the new field.
    # BUT - do not create the new field if it wasn't in the list passed in the original 
    # args, or if [] was passed in the original args. 
    
    # note that these are *not* columns in $them
    foreach my $field ( @has_many_fields )
    {
        # the 'next' condition is not tested because @wanted lists fields that probably 
        # don't exist yet, but should
        #next unless exists $form->field->{ $field };
        
        # if a custom field processor has been supplied, use that
        my $processor = $pre_process->{ $field };
        $me->_process_field( $them, $form, $field, $processor ) if $processor;
        next if $processor;        
        
        my $options = $me->_field_options( $them, $form, $field ) || 
            die "No options detected for '$them' field '$field'";
            
        my @many_pks;
        
        if ( ref $them )
        {
            my $rel = $meta->{ $field };
            
            my $accessor = $rel->accessor || die "no accessor for $field";
            
            my ( $related_class, undef ) = $me->table_meta( $them )->related_class_and_rel_type( $field );
            die "no foreign_class for $field" unless $related_class;
            
            my $foreign_pk = $related_class->primary_column;
            
            # don't be tempted to access pks directly in $iter->data - they may refer to an 
            # intermediate table via a mapping method
            my $iter = $them->$accessor;
            
            while ( my $obj = $iter->next )
            {
                die "retrieved " . ref( $obj ) . " '$obj' is not a $related_class" 
                    unless ref( $obj ) eq $related_class;
                    
                push @many_pks, $obj->$foreign_pk;
            }
        }    
                      
        $form->field( name     => $field,
                      value    => \@many_pks,
                      options  => $options,
                      multiple => 1,
                      );
    }
}

=item form_might_have

Also assumes a single primary column.

=cut

# this code is almost identical to form_has_many
sub form_might_have
{
    my ( $me, $them, $form, $pre_process ) = @_;
    
    my $meta = $them->meta_info( 'might_have' ) || return;
    
    my @might_have_fields = $me->_multiplicity_fields( $them, $form, 'might_have' );
    
    # note that these are *not* columns in $them
    foreach my $field ( @might_have_fields ) 
    {
        # the 'next' condition is not tested because @wanted lists fields that probably 
        # don't exist yet, but should
        
        # if a custom field processor has been supplied, use that
        my $processor = $pre_process->{ $field };
        $me->_process_field( $them, $form, $field, $processor ) if $processor;
        next if $processor;        
        
        my $options = $me->_field_options( $them, $form, $field ) || 
            die "No options detected for '$them' field '$field'";

        my $might_have_object_id;
        
        if ( ref $them )
        {        
            my $rel = $meta->{ $field };
            
            my $accessor = $rel->accessor || die "no accessor for $field";

            my ( $related_class, undef ) = $me->table_meta( $them )->related_class_and_rel_type( $field );
            die "no foreign_class for $field" unless $related_class;
            
            my $foreign_pk = $related_class->primary_column;
                        
            my $might_have_object = $them->$accessor;
            
            if ( $might_have_object )
            {
                die "retrieved " . ref( $might_have_object ) . " '$might_have_object' is not a $related_class" 
                    unless ref( $might_have_object ) eq $related_class;
            }
            
            $might_have_object_id = $might_have_object ? $might_have_object->$foreign_pk : undef; # was ''
        }
        
        $form->field( name     => $field,
                      value    => $might_have_object_id,
                      options  => $options,
                      );
    }
}

# Returns fields (in random order) that represent has_many or might_have relationships. 
# Note that if any of these fields are specified in __cdbi_original_args__, the order will be 
# preserved elsewhere during form construction.
sub _multiplicity_fields
{
    my ( $me, $them, $form, $rel ) = @_;
    
    die "Can't handle $rel relationships yet" unless $rel =~ /^(?:has_many|might_have)$/;

    my $meta = $them->meta_info( $rel ) || return;
    
    # @extras are field names that do not exist as columns in the db
    my @extras = keys %$meta;
    
    # if the call to as_form explicitly specified a list of fields, we only return 
    # fields from @extras that are in that list
    my %allowed = map { $_ => 1 } @{ $form->{__cdbi_original_args__}->{fields} || [ @extras ] };
    
    my @wanted = grep { $allowed{ $_ } } @extras;

    return @wanted;
}

# $field can be a CDBI column object, or the name of a has_many etc. field - i.e. not a column 
# in $them, but in another class
sub _field_options
{
    my ( $me, $them, $form, $field ) = @_;
    
    my ($related_class, undef) = $me->table_meta($them)->related_class_and_rel_type($field);
     
    return unless $related_class;
    
    return unless $related_class->isa( 'Class::DBI' );
    
    my $iter = $related_class->retrieve_all;            # potentially expensive
    
    my $pk = $related_class->primary_column;
    
    my @options;
    
    my $column_meta = $me->table_meta($them)->column($field);
    push @options, [ undef, 'n/a' ] if $column_meta and $column_meta->is_nullable;
    
    while ( my $object = $iter->next )                  # potentially very expensive
    {
        push @options, [ $object->$pk, ''.$object ]; 
    }
    
    if ( my $sorter = $me->_get_options_sorter( $them, $form, $field ) )
    {
        @options = sort $sorter @options;
    }
    
    return \@options;
}

sub _get_options_sorter
{
    my ( $me, $them, $form, $field ) = @_;

    # this href is a merge between the original args, and form_builder_defaults
    my $sorter = $form->__cdbi_original_args__->{options_sorters}->{$field};
                    
    return $sorter;
}

=item form_timestamp

Makes timestamp columns read only, since they will be set by the database.

The default is to use the C<TIMESTAMP> processor, which in turn points to the C<READONLY> 
processor, which sets the HTML C<readonly> attribute. 

If you prefer, you can replace the C<TIMESTAMP> processor with one that points to C<DISABLED> instead.

=cut

sub form_timestamp
{
    my ($me, $them, $form, $pre_process) = @_;
    
    foreach my $field ( $them->columns('All') )
    {
        next unless exists $form->field->{ $field->mutator };
    
        next unless $me->table_meta($them)->column_deep_type( $field->name ) eq 'timestamp';
    
        my $process = $me->_add_processors($field, $pre_process, 'TIMESTAMP'); 
        
        $me->_process_field($them, $form, $field, $process);
    }
}

=item form_text

Makes C<TEXT> columns into C<textarea> form fields. 

=cut 

sub form_text
{
    my ( $me, $them, $form, $pre_process ) = @_;

    foreach my $field ( $them->columns( 'All' ) )
    {
        next unless exists $form->field->{ $field->mutator };
    
        next unless $me->table_meta( $them )->column_deep_type( $field->name ) eq 'text';
    
        my $process = $me->_add_processors( $field, $pre_process, [ '+SET_type(textarea)', '+VALUE' ] ); 
        
        $me->_process_field( $them, $form, $field, $process );
    }
}

=item form_file

B<Unimplemented> - at the moment, you need to set the field type to C<file> manually, or 
in the C<process_fields> argument, set the field processor to C<FILE>.

Figures out if a column contains file data. 

If somebody can show me how to automatically detect that a column stores binary data, then this method 
could actually do something useful. 

If you are in the habit of using a naming convention that allows you to identify C<file> columns, then 
you could subclass L<Class::DBI::FormBuilder> and override this method:

    # use a naming convention to configure file columns
    sub form_file
    {
        my ( $me, $them, $form, $pre_process ) = @_;
    
        foreach my $field ( $them->columns( 'All' ) )
        {
            next unless $field->name =~ /^file_\w+$/;
        
            my $process = $me->_add_processors( $field, $pre_process, 'FILE' ); 
            
            $me->_process_field( $them, $form, $field, $process );
        }
    }

=cut

sub form_file
{
    my ( $me, $them, $form, $pre_process ) = @_;

    return;
}

=item form_process_extras

This processor adds any fields in the C<process_fields> setup that do not yet exist on the form. 
This is a useful method for adding custom fields (i.e. fields that do not represent anything about 
the CDBI object) to a form. 

You can skip this stage by setting C<< process_fields->{__SKIP_PROCESS_EXTRAS__} >> to a true 
value. For instance, in C<Maypole::FormBuilder::Model::setup_form_mode()>, this prevents any fields 
already present in C<process_fields> (e.g. because they were specified in C<form_builder_defaults>) 
from being added to the button form. 

=cut

sub form_process_extras
{
    my ( $me, $them, $form, $pre_process ) = @_;
    
    # this is a flag used in Maypole::FormBuilder::Model::setup_form_mode() button modes to 
    # prevent extra fields that may be mentioned in form_builder_defaults->{process_fields} 
    # from being added to the form
    #return if $pre_process->{__SKIP_PROCESS_EXTRAS__};
    
    my %process_extras = map { $_ => 1 } @{ $form->__cdbi_original_args__->{process_extras} };
    
    return unless %process_extras;
    
    foreach my $field ( keys %$pre_process )
    {
        next if exists $form->field->{ $field }; 
        
        #next if $field eq '__FINAL__'; # reserved for form_final
        
        next unless $process_extras{ $field };
        
        #my $process = $pre_process->{ $field };
        # this is just to help with debugging _add_processors
        my $process = $me->_add_processors( $field, $pre_process, [ ] );
        
        $me->_process_field( $them, $form, $field, $process );
    }    
}

=item form_final

After running all previous field processors (including C<form_process_extras>), this gives the 
chance to run code to modify all fields in the completed form. Use this by setting a field 
processor in the special C<__FINAL__> slot of C<process_fields>.

And avoid naming any of your normal columns or fields C<__FINAL__>.

=cut

sub form_final
{
    my ( $me, $them, $form, $pre_process ) = @_;
    
    my $final = $pre_process->{__FINAL__} or return;
    
    $me->_process_field( $them, $form, $_, $final ) for map { $_->name } $form->fields;
}

=back

=head2 Form handling methods

All these methods check the form like this

    return unless $fb->submitted && $fb->validate;
    
which allows you to say things like

    print Film->update_from_form( $form ) ? $form->confirm : $form->render;
    
That's pretty concise!

=over 4

=item create_from_form( $form )

Creates and returns a new object.

=cut

sub create_from_form 
{
    my ( $them, $form ) = @_;
    
    Carp::croak "create_from_form can only be called as a class method" if ref $them;
    
    return unless $form->submitted && $form->validate;
    
    my $me = $them->__form_builder_subclass__;
    
    my $created = $them->create( $me->_fb_create_data( $them, $form ) );
    
    $me->_update_many_to_many( $created, $form );
    
    return $created;
}

sub _fb_create_data
{
    my ( $me, $them, $form ) = @_;
    
    my $cols = {};
    
    my $data = $form->fields;
    
    foreach my $column ( $them->columns('All') ) 
    {
        next unless exists $data->{ $column->name };
        
        $cols->{ $column->mutator } = $data->{ $column->name };
    }
    
    return $cols;
}

=item create_from_multiform

Creates multiple new objects from a C<as_multiform> form submission.

=cut

# TODO: check if we need to call _update_many_many
sub create_from_multiform
{
    my ( $them, $form ) = @_;
    
    Carp::croak "create_from_multiform can only be called as a class method" if ref $them;
    
    return unless $form->submitted && $form->validate;

    my $form_data = $form->field; 
    
    my $items_data;
    
    foreach my $fname ( keys %$form_data )
    {
        $fname =~ /^R(\d+)__(\w+)$/;
        
        my $item_num = $1;
        my $col_name = $2;
        
        my $mutator = $them->find_column( $col_name )->mutator;
        
        $items_data->{ $item_num }->{ $mutator } = $form_data->{ $fname };
    }
    
    my @new = map { $them->create( $_ ) } values %$items_data;

    return @new;    
}

=item update_from_form( $form )

Updates an existing CDBI object. 

If called on an object, will update that object.

If called on a class, will first retrieve the relevant object (via C<retrieve_from_form>).

=cut

sub update_from_form 
{
    my ( $proto, $form ) = @_;
    
    my $them = ref( $proto ) ? $proto : $proto->retrieve_from_form( $form );
    
    Carp::croak "No object found matching submitted primary key data" unless $them;
    
    my $me = $proto->__form_builder_subclass__;
    
    $me->_run_update( $them, $form );
    
    $me->_update_many_to_many( $them, $form );
    
    return $them;
}

sub _run_update 
{
    my ( $me, $them, $fb ) = @_;
    
    return unless $fb->submitted && $fb->validate;
    
    my $formdata = $fb->fields;
    
    # I think this is now unnecessary (0.4), because pks are in keepextras
    delete $formdata->{ $_ } for map {''.$_} $them->primary_columns;
    
    # assumes no extra fields in the form
    #$them->set( %$formdata );
    
    # Start with all possible columns. Only ask for the subset represented 
    # in the form. This allows correct handling of fields that result in 
    # 'missing' entries in the submitted data - e.g. checkbox groups with 
    # no item selected will not even appear in the raw request data, but here
    # they should result in an undef value being sent to the object.
    my %coldata = map  { $_->mutator => $formdata->{ $_->name } } 
                  grep { exists $formdata->{ $_->name } }
                  $them->columns( 'All' );
    
    $them->set( %coldata );
    
    $them->update;
    
    return $them;
}


# from Ron McClain:
sub _update_many_to_many 
{
    my ( $me, $obj, $form ) = @_;
    
    my $has_many = $obj->meta_info('has_many') || return;
    
    foreach my $field ( keys %{ $form->fields } ) 
    {
        next unless $has_many->{$field};
        
        # many-many
        next unless $has_many->{$field}->{args}->{mapping};       
        
        my $mkey   = $has_many->{$field}->{args}->{mapping}->[0];
        my $fkey   = $has_many->{$field}->{args}->{foreign_key};
        my $fclass = $has_many->{$field}->{foreign_class};
        
        my %rel_exists;
        
        foreach my $rel ( $fclass->search( $fkey => $obj->id ) ) 
        {
            if ( grep { $rel->$mkey->id == $_ } $form->field($field) )
            {
                $rel_exists{ $rel->$mkey->id }++;
            } 
            else 
            {
                $rel->delete;
            }
        }
        
        foreach my $val ( $form->field($field) ) 
        {
            $fclass->create( { $fkey => $obj->id, 
                               $mkey => $val,
                               } ) 
                unless $rel_exists{$val};
        }
    }
}

# Also, this patch only applies to many-many.  Not one-many.  I got to
# thinking about it, and it doesn't make sense to me  have a select list
# for one-many with existing records..  Because if you edit a record and
# select a record to relate to it..  The related record may already be
# associated with a separate record, and it would kill that association..
# Not intuitive.  But for many-many, I don't see the downside of having
# something like this be standard.  The only thing I can think of is, what
# if the glue table has additional columns besides the two foreign keys?
# I can't think of an example right now, but I guess it's possible.  The
# other thing I don't quite understand is why
# meta_info->field->args->mapping is an array and not a scalar.  I just
# pull off the first element, but I don't know whether it's possible that
# there be more elements than that, and what they mean.

=item update_or_create_from_form

Class method.

Attempts to look up an object (using primary key data submitted in the form) and update it. 

If none exists (or if no values for primary keys are supplied), a new object is created. 

=cut

sub update_or_create_from_form
{
    my ( $them, $form ) = @_;
    
    Carp::croak "update_or_create_from_form can only be called as a class method" if ref $them;

    $them->__form_builder_subclass__->_run_update_or_create_from_form( $them, $form );
}

sub _run_update_or_create_from_form
{
    my ( $me, $them, $form ) = @_;

    return unless $form->submitted && $form->validate;

    my $object = $them->retrieve_from_form( $form );
    
    return $object->update_from_form( $form ) if $object;
    
    $them->create_from_form( $form );
}

=back

=head2 Search methods

Note that search methods (except for C<retrieve_from_form>) will return a CDBI iterator 
in scalar context, and a (possibly empty) list of objects in list context.

All the search methods except C<retrieve_from_form> require that the submitted form should be 
built using C<search_form> (not C<as_form>). Otherwise the form may fail validation checks 
because of missing required fields specified by C<as_form> (C<search_form> does not automatically 
configure any fields as required).

=over 4

=item retrieve_from_form

Use primary key data in a form to retrieve a single object.

=cut

sub retrieve_from_form
{
    my ( $them, $form ) = @_;
    
    Carp::croak "retrieve_from_form can only be called as a class method" if ref $them;

    $them->__form_builder_subclass__->_run_retrieve_from_form( $them, $form );
}

sub _run_retrieve_from_form
{
    my ( $me, $them, $form ) = @_;
    
    # we don't validate because pk data must side-step validation as it's 
    # unknowable in advance whether they will even be present. 
    #return unless $fb->submitted && $fb->validate;
    
    my %pkdata = map { $_ => $form->cgi_param( $_->mutator ) || undef } $them->primary_columns;
    
    return $them->retrieve( %pkdata );
}

=item search_from_form

Lookup by column values.

=cut

sub search_from_form 
{
    my ( $them, $form ) = @_;
    
    Carp::croak "search_from_form can only be called as a class method" if ref $them;

    $them->__form_builder_subclass__->_run_search_from_form( $them, '=', $form );
}

=item search_like_from_form

Allows wildcard searches (% or _).

Note that the submitted form should be built using C<search_form>, not C<as_form>. 

=cut

sub search_like_from_form
{
    my ( $them, $form ) = @_;
    
    Carp::croak "search_like_from_form can only be called as a class method" if ref $them;

    $them->__form_builder_subclass__->_run_search_from_form( $them, 'LIKE', $form );
}

sub _run_search_from_form
{    
    my ( $me, $them, $search_type, $form ) = @_;
    
    return unless $form->submitted && $form->validate;

    my %searches = ( LIKE => 'search_like',
                     '='  => 'search',
                     );
                     
    my $search_method = $searches{ $search_type };
    
    my @search = $me->_get_search_spec( $them, $form );
    
    my @modifiers = qw( order_by order_direction ); # others too
    
    my %search_modifiers = $me->_get_search_spec( $them, $form, \@modifiers );
    
    push( @search, \%search_modifiers ) if %search_modifiers;
    
    return $them->$search_method( @search );
}

sub _get_search_spec
{
    my ( $me, $them, $form, $fields ) = @_;

    my @fields = $fields ? @$fields : map { $_->accessor } $them->columns( 'All' );

    # this would miss multiple items
    #my $formdata = $fb->fields;
    
    my $formdata;
    
    foreach my $field ( $form->fields )
    {
        my @data = $field->value;
        
        $formdata->{ $field } = @data > 1 ? \@data : $data[0];
    }
    
    return map  { $_ => $formdata->{ $_ } } 
           grep { defined $formdata->{ $_ } } # don't search on unsubmitted fields
           @fields;
}

=item search_where_from_form

L<Class::DBI::AbstractSearch|Class::DBI::AbstractSearch> must be loaded in your 
CDBI class for this to work.

If no search terms are specified, then the search 

    WHERE 1 = 1
    
is executed (returns all rows), no matter what search operator may have been selected.

=cut

sub search_where_from_form
{
    my ( $them, $form ) = @_;
    
    Carp::croak "search_where_from_form can only be called as a class method" if ref $them;

    $them->__form_builder_subclass__->_run_search_where_from_form( $them, $form );
}

# have a look at Maypole::Model::CDBI::search()
sub _run_search_where_from_form
{
    my ( $me, $them, $form ) = @_;
    
    return unless $form->submitted && $form->validate;

    my %search_data = $me->_get_search_spec( $them, $form );
    
    # clean out empty fields
    do { delete( $search_data{ $_ } ) unless $search_data{ $_ } } for keys %search_data;
    
    # these match fields added in search_form()
    my %modifiers = ( search_opt_cmp      => 'cmp', 
                      search_opt_order_by => 'order_by',
                      );
    
    my %search_modifiers = $me->_get_search_spec( $them, $form, [ keys %modifiers ] );
    
    # rename modifiers for SQL::Abstract - taking care not to autovivify entries
    $search_modifiers{ $modifiers{ $_ } } = delete( $search_modifiers{ $_ } ) 
        for grep { $search_modifiers{ $_ } } keys %modifiers;
    
    # return everything if no search terms specified
    unless ( %search_data )
    {
        $search_data{1}        = 1;
        $search_modifiers{cmp} = '=';
    }
    
    my @search = %search_modifiers ? ( \%search_data, \%search_modifiers ) : %search_data;
    
    return $them->search_where( @search );
}

=item find_or_create_from_form

Does a C<find_or_create> using submitted form data. 

=cut
    
sub find_or_create_from_form
{
    my ( $them, $form ) = @_;
    
    Carp::croak "find_or_create_from_form can only be called as a class method" if ref $them;

    $them->__form_builder_subclass__->_run_find_or_create_from_form( $them, $form );
}

sub _run_find_or_create_from_form
{
    my ( $me, $them, $form ) = @_;

    return unless $form->submitted && $form->validate;

    my %search_data = $me->_get_search_spec( $them, $form );
    
    return $them->find_or_create( \%search_data );    
}

=item retrieve_or_create_from_form

Attempts to look up an object. If none exists, a new object is created. 

This is similar to C<update_or_create_from_form>, except that this method will not 
update pre-existing objects. 

=cut

sub retrieve_or_create_from_form
{
    my ( $them, $form ) = @_;
    
    Carp::croak "retrieve_or_create_from_form can only be called as a class method" if ref $them;

    $them->__form_builder_subclass__->_run_retrieve_or_create_from_form( $them, $form );
}

sub _run_retrieve_or_create_from_form
{
    my ( $me, $them, $form ) = @_;

    return unless $form->submitted && $form->validate;

    my $object = $them->retrieve_from_form( $form );
    
    return $object if $object;
    
    $them->create_from_form( $form );
}


=back

=cut

# ---------------------------------------------------------------------------------- validation -----

sub _valid_map
{
    my ( $me, $type ) = @_;
    
    return $ValidMap{ $type };
}

# $fb_args is the args hash that will be sent to CGI::FB to construct the form. 
# Here we re-write $fb_args->{validate}
sub _setup_auto_validation 
{
    my ( $me, $them, $fb_args ) = @_;
    
    # this simply returns either the auto-validation spec (as set up by the caller), or 
    # undef (if the caller has set up a standard CGI::FB validation spec)
    my %args = $me->_get_auto_validate_args( $them );
     
    return unless %args;
    
    my $debug = delete $args{debug};
    warn "auto-validating $them\n" if $debug;
    
    # validate and columns are the same thing. validate matches the terminology 
    # used in CGI::FB, so it should be retained, but 'columns' is more descriptive, 
    # and to be preferred
    if ( exists $args{validate} and exists $args{columns} )
    {
        Carp::croak "Automatic validation profile contains both 'validate' and 'columns' entries. " . 
                "Use one or other, not both (they're aliases)";
    }
    
    my $v_cols        = delete $args{columns} || delete $args{validate} || {}; 
    my $skip_cols     = delete $args{skip_columns}     || [];
    my $match_cols    = delete $args{match_columns}    || {}; 
    my $v_types       = delete $args{validate_types}   || {}; 
    my $match_types   = delete $args{match_types}      || {}; 
    
    # anything left over is an error
    if ( my @unknown = keys %args )
    {
        Carp::croak "Unknown keys in auto-validation spec: " . join( ', ', @unknown );
    }
    
    my %skip = map { $_ => 1 } @$skip_cols;
    
    my %validate; 
    
    foreach my $field ( @{ $fb_args->{fields} } ) 
    {
        my $column   = ref $field ? $field : $them->find_column($field);
        my $col_name = ref $field ? $column->name : $field;
    
        next if $skip{$col_name};    
        
        # this will get added at the end
        next if $v_cols->{$col_name}; 
        
        # look for columns with options
        # TODO - what about related columns? - do not want to add 10^6 db rows to validation
        #           - the caller just has to set up a different config for these cases
             
        my $options = $them->form_builder_defaults->{options} || {};
        
        my $o = $options->{$col_name};
        
        # $o could be an aref of arefs, each consisting of a value and a label - 
        # we only want the values. Note that in general, there could be a mix of 
        # arrayrefs and strings in the options list, e.g. for a leading empty item 
        if ( ref($o) eq 'ARRAY' )
        {
            $o = [ map { ref $_ eq 'ARRAY' ? $_->[0] : $_ } @$o ];
        }
        
        unless ($o)
        {
            # if $fb_args has entries for has_many fields, this will croak
            my $column_meta = $me->table_meta( $them )->column( $col_name );
            
            last unless $column_meta; # it's a has_many (or similar) field
            
            my ( $series, undef ) = $column_meta->options;
            $o = $series; 
            warn "(Probably) setting validation to options (@$o) for $col_name in $them" 
                if ( $debug > 1 and @$o );
            undef($o) unless @$o;            
        }
        
        my $type = $me->table_meta($them)->column_deep_type($col_name);
        
        die "No type for $col_name in $them" unless $type;
        
        my $v = $o || $v_types->{$type}; 
                 
        foreach my $regex ( keys %$match_types )
        {
            last if $v;
            $v = $match_types->{$regex} if $type =~ $regex;
        }
        
        foreach my $regex ( keys %$match_cols )
        {
            last if $v;
            $v = $match_cols->{$regex} if $col_name =~ $regex;
        }
        
        my $skip_ts = ( ( $type eq 'timestamp' ) && ! $v );
        
        warn "Skipping $them $col_name [timestamp]\n" if ( $skip_ts and $debug > 1 );
        
        next if $skip_ts;
        
        $v ||= $me->_valid_map($type) || '';
        
        my $fail = "No validate type detected for column $col_name, type $type in $them"
            unless $v;
            
        $fail and $args{strict} ? die $fail : warn $fail;
    
        my $type2 = substr( $type, 0, 25 );
        $type2 .= '...' unless $type2 eq $type;
        
        warn sprintf "Validating %s %s [%s] as %s\n", $them, $col_name, $type2, $v
                if $debug > 1;
        
        $validate{$col_name} = $v if $v;
    }
    
    my $validation = {%validate, %$v_cols};
    
    if ($debug)
    {
        Data::Dumper->require || die $@;
        my $label = ref($them) ? ref($them) . "($them)" : $them;
        warn "Setting up validation for $label: ".Data::Dumper::Dumper($validation);
    }
    
    $fb_args->{validate} = $validation;
    
    return;
}

sub _get_auto_validate_args
{
    my ( $me, $them ) = @_;
    
    my $fb_defaults = $them->form_builder_defaults;
    
    if ( %{ $fb_defaults->{validate} || {} } && %{ $fb_defaults->{auto_validate} || {} } )
    {
        Carp::croak 'Got validation AND auto-validation settings in form_builder_defaults - ' . 
                        'should only have one or the other';
    }
    
    # don't do auto-validation if the caller has set up a standard CGI::FB validation spec
    return if %{ $fb_defaults->{validate} || {} };
    
    # stop lots of warnings when testing debug value, and ensure something is set so the cfg exists test passes
    $fb_defaults->{auto_validate}->{debug} ||= 0;
    
    return %{ $fb_defaults->{auto_validate} };
}

# ---------------------------------------------------------------------------------- / validation -----

=head1 TODO

has_many fields are not currently being validated (the code to set up the validation config 
was choking on has_many columns, so for now, they're ignored).

Use the proper column accessors (i.e. $column->name for form field names, $column->accessor 
for 'get', and $column->mutator foe 'set' operations).

Add support for local plugins - i.e. specify a custom namespace to search for plugins, before 
searching the CDBI::FB::Plugin namespace.

Better merging of attributes. For instance, it'd be nice to set some field attributes 
(e.g. size or type) in C<form_builder_defaults>, and not lose them when the fields list is 
generated and added to C<%args>. 

Regex and column type entries for C<process_fields>, analogous to validation settings.

Use preprocessors in form_has_a, form_has_many and form_might_have.

Transaction support - see http://search.cpan.org/~tmtm/Class-DBI-0.96/lib/Class/DBI.pm#TRANSACTIONS
and http://wiki.class-dbi.com/index.cgi?AtomicUpdates

Wrap the call to C<$form_modify> in an eval, and provide a better diagnostic if the call 
fails because it's trying to handle a relationship that has not yet been coded - e.g. is_a

Store CDBI errors somewhere on the form. For instance, if C<update_from_form> fails because 
no object could be retrieved using the form data. 

Detect binary data and build a file upload widget. 

C<is_a> relationships.

C<enum> and C<set> equivalent column types in other dbs.

Figure out how to build a form for a related column when starting from a class, not an object
(pointed out by Peter Speltz). E.g. 

   my $related = $object->some_col;

   print $related->as_form->render;
   
will not work if $object is a class. Have a look at Maypole::Model::CDBI::related_class. 

Integrate fields from a related class object into the same form (e.g. show address fields 
in a person form, where person has_a address). B<UPDATE>: fairly well along in 0.32 (C<as_form_with_related>).
B<UPDATE>: as_form_with_related() is deprecated (and still not working) Once it works properly, it 
will be merged into C<as_form>. 

C<_splice_form> needs to handle custom setup for more relationship types. 

=head1 AUTHOR

David Baird, C<< <cpan@riverside-cms.co.uk> >>

=head1 BUGS

If no fields are explicitly required, then *all* fields will become required automatically, because 
CGI::FormBuilder by default makes any field with validation become required, unless there is at least 
1 field specified as required. 

Please report any bugs or feature requests to
C<bug-class-dbi-plugin-formbuilder@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Class-DBI-FormBuilder>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

Looking at the code (0.32), I suspect updates to has_many accessors are not implemented, since the update
methods only fetch data for columns( 'All' ), which doesn't include has_many accessors/mutators. 

=head1 ACKNOWLEDGEMENTS

The following people have provided useful discussions, bug reports, and patches: 

Dave Howorth, James Tolley, Ron McClain, David Kamholz.

=head1 COPYRIGHT & LICENSE

Copyright 2005 David Baird, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Class::DBI::Plugin::FormBuilder

__END__

Example of a dumped CDBI meta_info structure for BeerDB::Beer:

$VAR1 = {
          'has_a' => {
                       'style' => bless( {
                                           'foreign_class' => 'BeerFB::Style',
                                           'name' => 'has_a',
                                           'args' => {},
                                           'class' => 'BeerFB::Beer',
                                           'accessor' => bless( {
                                                                  '_groups' => {
                                                                                 'All' => 1
                                                                               },
                                                                  'name' => 'style',
                                                                  'mutator' => 'style',
                                                                  'placeholder' => '?',
                                                                  'accessor' => 'style'
                                                                }, 'Class::DBI::Column' )
                                         }, 'Class::DBI::Relationship::HasA' ),
                       'brewery' => bless( {
                                             'foreign_class' => 'BeerFB::Brewery',
                                             'name' => 'has_a',
                                             'args' => {},
                                             'class' => 'BeerFB::Beer',
                                             'accessor' => bless( {
                                                                    '_groups' => {
                                                                                   'All' => 1
                                                                                 },
                                                                    'name' => 'brewery',
                                                                    'mutator' => 'brewery',
                                                                    'placeholder' => '?',
                                                                    'accessor' => 'brewery'
                                                                  }, 'Class::DBI::Column' )
                                           }, 'Class::DBI::Relationship::HasA' )
                     },
          'has_many' => {
                          'pubs' => bless( {
                                             'foreign_class' => 'BeerFB::Handpump',
                                             'name' => 'has_many',
                                             'args' => {
                                                         'mapping' => [
                                                                        'pub'
                                                                      ],
                                                         'foreign_key' => 'beer',
                                                         'order_by' => undef
                                                       },
                                             'class' => 'BeerFB::Beer',
                                             'accessor' => 'pubs'
                                           }, 'Class::DBI::Relationship::HasMany' )
                        }
        };


And for BeerFB::Pub:

$VAR1 = {
          'has_many' => {
                          'beers' => bless( {
                                              'foreign_class' => 'BeerFB::Handpump',
                                              'name' => 'has_many',
                                              'args' => {
                                                          'mapping' => [
                                                                         'beer'
                                                                       ],
                                                          'foreign_key' => 'pub',
                                                          'order_by' => undef
                                                        },
                                              'class' => 'BeerFB::Pub',
                                              'accessor' => 'beers'
                                            }, 'Class::DBI::Relationship::HasMany' )
                        }
        };

And for BeerFB::Handpump:

$VAR1 = {
          'has_a' => {
                       'pub' => bless( {
                                         'foreign_class' => 'BeerFB::Pub',
                                         'name' => 'has_a',
                                         'args' => {},
                                         'class' => 'BeerFB::Handpump',
                                         'accessor' => bless( {
                                                                'name' => 'pub',
                                                                '_groups' => {
                                                                               'All' => 1
                                                                             },
                                                                'mutator' => 'pub',
                                                                'placeholder' => '?',
                                                                'accessor' => 'pub'
                                                              }, 'Class::DBI::Column' )
                                       }, 'Class::DBI::Relationship::HasA' ),
                       'beer' => bless( {
                                          'foreign_class' => 'BeerFB::Beer',
                                          'name' => 'has_a',
                                          'args' => {},
                                          'class' => 'BeerFB::Handpump',
                                          'accessor' => bless( {
                                                                 'name' => 'beer',
                                                                 '_groups' => {
                                                                                'All' => 1
                                                                              },
                                                                 'mutator' => 'beer',
                                                                 'placeholder' => '?',
                                                                 'accessor' => 'beer'
                                                               }, 'Class::DBI::Column' )
                                        }, 'Class::DBI::Relationship::HasA' )
                     }
        };


A plain has_many (not part of a many_many) - a consultant has_many referees
$VAR1 = bless( {
                 'foreign_class' => 'Referee',
                 'name' => 'has_many',
                 'args' => {
                             'mapping' => [],
                             'foreign_key' => 'consultant',
                             'order_by' => undef
                           },
                 'class' => 'Consultant',
                 'accessor' => 'referees'
               }, 'Class::DBI::Relationship::HasMany' );

