package Chandra::Form::Validator;

use strict;
use warnings;

our $VERSION = '0.28';

use Chandra;

sub validate {
    my ($class, $form, $data) = @_;
    return $form->validate($data);
}

sub validation_js {
    my ($class, $form) = @_;
    my $form_id = $form->id;
    my $fields_ref = $form->{_fields};
    return '' unless $fields_ref && ref $fields_ref eq 'ARRAY';

    my @rules;
    for my $entry (@$fields_ref) {
        next unless ref $entry eq 'HASH';
        my $name = $entry->{name} // next;
        my $type = $entry->{type} // 'text';
        next if $type eq 'hidden' || $type eq 'submit' || $type eq 'group';

        my $opts = $entry->{opts};
        next unless $opts && ref $opts eq 'HASH';

        my @field_rules;
        if ($opts->{required}) {
            my $msg = _js_escape($opts->{required_msg} || ($opts->{label} || $name) . ' is required');
            push @field_rules, "{type:'required',msg:'$msg'}";
        }
        if (defined $opts->{minlength}) {
            my $msg = _js_escape($opts->{minlength_msg} || "Must be at least $opts->{minlength} characters");
            push @field_rules, "{type:'minlength',val:$opts->{minlength},msg:'$msg'}";
        }
        if (defined $opts->{maxlength}) {
            my $msg = _js_escape($opts->{maxlength_msg} || "Must be at most $opts->{maxlength} characters");
            push @field_rules, "{type:'maxlength',val:$opts->{maxlength},msg:'$msg'}";
        }
        if (defined $opts->{min}) {
            my $msg = _js_escape($opts->{min_msg} || "Must be at least $opts->{min}");
            push @field_rules, "{type:'min',val:$opts->{min},msg:'$msg'}";
        }
        if (defined $opts->{max}) {
            my $msg = _js_escape($opts->{max_msg} || "Must be at most $opts->{max}");
            push @field_rules, "{type:'max',val:$opts->{max},msg:'$msg'}";
        }
        if ($opts->{pattern} && !ref $opts->{pattern}) {
            my $pat = $opts->{pattern};
            $pat =~ s/\\/\\\\/g;
            my $msg = _js_escape($opts->{pattern_msg} || 'Invalid format');
            push @field_rules, "{type:'pattern',val:/$pat/,msg:'$msg'}";
        }
        if ($type eq 'email') {
            my $msg = _js_escape($opts->{email_msg} || 'Invalid email address');
            push @field_rules, "{type:'email',msg:'$msg'}";
        }

        if (@field_rules) {
            my $ename = _js_escape($name);
            push @rules, "'$ename':[" . join(',', @field_rules) . "]";
        }
    }

    return '' unless @rules;
    my $rules_js = '{' . join(',', @rules) . '}';

    return <<"JS";
(function(){
var rules=$rules_js;
var form=document.getElementById('$form_id');
if(!form)return;
form.addEventListener('submit',function(e){
    var errors={},hasErr=false;
    for(var n in rules){
        var el=form.querySelector('[name=\"'+n+'\"]');
        var v=el?el.value:'';
        for(var i=0;i<rules[n].length;i++){
            var r=rules[n][i];
            if(r.type==='required'&&!v.trim()){errors[n]=r.msg;hasErr=true;break;}
            if(r.type==='minlength'&&v.length<r.val){errors[n]=r.msg;hasErr=true;break;}
            if(r.type==='maxlength'&&v.length>r.val){errors[n]=r.msg;hasErr=true;break;}
            if(r.type==='min'&&parseFloat(v)<r.val){errors[n]=r.msg;hasErr=true;break;}
            if(r.type==='max'&&parseFloat(v)>r.val){errors[n]=r.msg;hasErr=true;break;}
            if(r.type==='pattern'&&!r.val.test(v)){errors[n]=r.msg;hasErr=true;break;}
            if(r.type==='email'&&!/^[^\\s\@]+\@[^\\s\@]+\\.[^\\s\@]+\$/.test(v)){errors[n]=r.msg;hasErr=true;break;}
        }
    }
    var errs=form.querySelectorAll('.chandra-error');
    for(var i=0;i<errs.length;i++)errs[i].textContent='';
    if(hasErr){
        e.preventDefault();e.stopPropagation();
        for(var n in errors){
            var errEl=form.querySelector('.chandra-error[data-field=\"'+n+'\"]');
            if(!errEl){var f=form.querySelector('[name=\"'+n+'\"]');if(f)errEl=f.parentElement.querySelector('.chandra-error');}
            if(errEl)errEl.textContent=errors[n];
        }
        return false;
    }
});
form.addEventListener('focusout',function(e){
    var el=e.target,n=el.name;
    if(!n||!rules[n])return;
    var v=el.value,errEl=el.parentElement.querySelector('.chandra-error');
    if(!errEl)return;errEl.textContent='';
    for(var i=0;i<rules[n].length;i++){
        var r=rules[n][i];
        if(r.type==='required'&&!v.trim()){errEl.textContent=r.msg;break;}
        if(r.type==='minlength'&&v.length>0&&v.length<r.val){errEl.textContent=r.msg;break;}
        if(r.type==='pattern'&&v.length>0&&!r.val.test(v)){errEl.textContent=r.msg;break;}
        if(r.type==='email'&&v.length>0&&!/^[^\\s\@]+\@[^\\s\@]+\\.[^\\s\@]+\$/.test(v)){errEl.textContent=r.msg;break;}
    }
});
})();
JS
}

sub _js_escape {
    my ($s) = @_;
    $s =~ s/\\/\\\\/g;
    $s =~ s/'/\\'/g;
    return $s;
}

1;

__END__

=head1 NAME

Chandra::Form::Validator - Form validation for Chandra::Form

=head1 SYNOPSIS

    use Chandra::Form::Validator;

    # Server-side validation (calls XS validate on form)
    my $errors = Chandra::Form::Validator->validate($form, \%data);
    if ($errors) {
        $app->eval($form->show_errors_js($errors));
    }

    # Client-side validation JS
    my $js = Chandra::Form::Validator->validation_js($form);
    $app->eval($js);

=head1 SEE ALSO

L<Chandra::Form>

=cut
