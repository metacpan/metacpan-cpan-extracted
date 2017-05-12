package CGI::Ex::App::Constants;

=head1 NAME

CGI::Ex::App::Constants - Easier access to magic App values

=cut

use vars qw(%constants @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION);
use strict;
use warnings;
use Exporter qw(import); # allow for goto from CGI::Ex::App
use base qw(Exporter);

$VERSION = '2.44';

BEGIN {
my $all = {
    App__allow_morph__allow_reblessing            => '1 - This will allow changing MyApp to MyApp::MyStep when on step my_step',
    App__allow_morph__force_reblessing            => '2 - This will force changing MyApp to MyApp::MyStep when on step my_step',
    App__allow_morph__no_auto_reblessing          => '0 - We will not look for another package to bless into',
    App__auth_args       => 'should return a hashref of args to pass to auth_obj',
    App__auth_obj        => 'should return a auth_obj - used when require_auth is true',
    App__file_print      => 'should file path, or be a scalar reference to the template to print',
    App__file_val        => 'should return a file path or a hash_validation hashref (default is {})',
    App__fill_args       => 'should return a hashref of args to pass to CGI::Ex::Fill::fill (default {})',
    App__fill_template   => 'void context - uses hashes to fill the template',
    App__finalize__failed_and_show_page           => '0 - additional processing failed so show the page',
    App__finalize__finished_and_move_to_next_step => '1 - default',
    App__finalize__finished_but_show_page         => '',
    App__form_name       => 'must return a name',
    App__generate_form   => 'return coderef to form that can generate the form based on hash_validation',
    App__get_valid_auth  => 'needs to return a CGI::Ex::Auth::Data object (which can be either true or false)',
    App__hash_base       => 'should return a hashref',
    App__hash_common     => 'should return a hashref',
    App__hash_errors     => 'should return a hashref of errors that occurred on the page (normally populated via add_error)',
    App__hash_fill       => 'should return a hashref of things to get filled in forms in the template',
    App__hash_form       => 'should return a hashref - default is $self->form - normally not overridden',
    App__hash_swap       => 'should return a hashref of things to process in the template',
    App__hash_validation => 'should return a CGI::Ex::Validate compatible hashref or {} (default empty hashref means all submitted information is always ok to finalize)',
    App__info_complete__fail_and_show_page        => '0 - we were not ready to finalize the data either because there was not any, or it failed validation',
    App__info_complete__succeed_and_run_finalize  => '1 - occurs because data is ready and is good or because there was no hash_validation to test against',
    App__js_validation   => 'return coderef to form that will generate javascript based validation based on hash_validation',
    App__morph           => 'void context - used to rebless into other package',
    App__morph_package   => 'return package name derivative for use when allow_morph is true (see perldoc on morph, morph_package, morph_base)',
    App__name_module     => 'return name of application - used when mapping to file_system (see file_print, file_val, conf_file)',
    App__name_step       => 'return step of current request (default is $current_step) - used for mapping to file_system',
    App__path_info_map   => 'return arrayref of matching arrayrefs - first one matching is used - others abort (only applies to current step)',
    App__path_info_map_base                       => 'return arrayref of matching arrayrefs - first one matching is used - others abort (ran before nav_loop)',
    App__post_loop__do_not_recurse                => '1 - can be used to abort navigation if the loop is about to recurse to default step - no additional headers will be sent',
    App__post_loop__recurse_loop                  => 0,
    App__post_navigate                            => 'void context - called at the end of navigation unless $self->{_no_post_navigate} is true',
    App__post_print                               => 'void context - run code after page is diplayed to user',
    App__post_step__abort_navigation_flow         => '1 - no additional headers will be sent',
    App__post_step__move_to_next_step             => 0,
    App__pre_loop__begin_loop                     => 0,
    App__pre_loop__do_not_loop                    => '1 - can be used to abort the nav_loop call early on - no additional headers will be sent',
    App__pre_navigate__continue                   => '0 - go ahead and navigate the request',
    App__pre_navigate__stop                       => '1 - can be used to abort the navigate call early on - no additional headers will be sent',
    App__pre_step__abort_navigation_flow          => '1 - no additional headers will be sent',
    App__pre_step__continue_current_step          => 0,
    App__prepare__fail_and_show_page              => 0,
    App__prepare__ok_move_to_info_complete        => '1 - default',
    App__prepared_print                           => 'void context - gathers hashes - then calls print',
    App__print                                    => 'void context - uses hashes to swap and fill file_print, then calls print_out',
    App__print_out                                => 'void context - prints headers and prepared content',
    App__ready_validate__data_not_ready_show_page => '0 - either validate_when_data was alse and it was a GET',
    App__ready_validate__ready_to_validate_data   => '1 - either validate_when_data was true or we received a POST',
    App__refine_path                              => 'void context - manipulates the path after a step.  set_ready_validate(0) if next_step is true',
    App__require_auth__needs_authentication       => 1,
    App__require_auth__no_authentication_needed   => 0,
    App__run_step__move_to_next_step              => 0,
    App__run_step__request_completed              => '1 - no additional headers will be sent',
    App__set_ready_validate                       => 'void context - sets ready_validate to true (fakes REQUEST_METHOD to POST OR GET)',
    App__skip__continue_current_step              => 0,
    App__skip__move_to_next_step                  => '1 - make sure the path has a next step or it will default to main',
    App__swap_template   => 'should return swapped template (passed $step, $file, $swap)',
    App__template_args   => 'should return a hashref to pass to template_obj',
    App__template_obj    => 'should return a Template::Alloy type object for swapping the template (passed template_args)',
    App__unmorph         => 'void context - re-reblesses back to the original class before morph',
    App__val_args        => 'should return a hashref to pass to val_obj',
    App__val_obj         => 'should return a CGI::Ex::Validate type object for validating the data',
    App__validate__data_was_ok                    => '1 - request data either passed hash_validation or hash_validation was empty - make info_complete succeed',
    App__validate__failed_validation              => 0,
    App__validate_when_data__succeed_if_data      => '1 - will be true if there is no hash_validation, or a key from hash_validation was in the form',
    App__validate_when_data__use_ready_validate   => 0,
};

no strict 'refs';
while (my ($method, $val) = each %$all) {
    my ($prefix, $tag, $name) = split /__/, $method;
    if (! $name) {
        $constants{$tag} = $val;
        next;
    }
    $constants{$tag}->{$name} = $val;

    my $tags = $EXPORT_TAGS{"App__${tag}"} ||= [];
    push @{ $EXPORT_TAGS{"App"} }, $method;
    push @$tags,     $method;
    push @EXPORT,    $method;
    push @EXPORT_OK, $method;

    $val =~ s/\s+-.*//;
    $val *= 1 if $val =~ /^\d+$/;
    *{__PACKAGE__."::$method"} = sub () { $val };
}

}; # end of BEGIN

sub constants {
    print __PACKAGE__."\n---------------------\n";
    no strict 'refs';
    for (sort @EXPORT_OK) {
        print "$_ (".$_->().")\n";
    }
}

sub tags {
    print __PACKAGE__." Tags\n---------------------\n";
    print "$_\n" for sort keys %EXPORT_TAGS;
}

sub details {
    require Data::Dumper;
    local $Data::Dumper::SortKeys = 1;
    print Data::Dumper::Dumper(\%constants);
}

1;

__END__

=head1 SYNOPSIS

    use base qw(CGI::Ex::App);
    use CGI::Ex::App::Constants; # load all
    use CGI::Ex::App::Constants qw(:App); # also load all
    use CGI::Ex::App qw(:App); # also load all

    __PACKAGE__->navigate;

    sub main_run_step {
        my $self = shift;

        $self->cgix->print_content_type;
        print "Hello world\n";

        return App__run_step__request_completed;
    }


    # you can request only certain tags
    use CGI::Ex::App::Constants qw(:App__run_step);
    use CGI::Ex::App qw(:App__run_step);

    # you can request only certain constants
    use CGI::Ex::App::Constants qw(App__run_step__request_completed);
    use CGI::Ex::App qw(App__run_step__request_completed);

=head1 CONSTANTS

To see a list of the importable tags type:

   perl -MCGI::Ex::App::Constants -e 'CGI::Ex::App::Constants::tags()'

To see a list of the importable constants type:

   perl -MCGI::Ex::App::Constants -e 'CGI::Ex::App::Constants::constants()'

To see a little more discussion about the hooks and other CGI::Ex::App options type:

   perl -MCGI::Ex::App::Constants -e 'CGI::Ex::App::Constants::details()'

=cut
