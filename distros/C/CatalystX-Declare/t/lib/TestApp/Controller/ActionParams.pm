use CatalystX::Declare;
namespace TestApp;

role hasActionParams {
    has [qw/p1 p2/] => (is=>'ro', lazy_build=>1);

    method _build_p1 {
        join ',', @{$self->attributes->{p1}};
    }
    method _build_p2 {
        join ',', @{$self->attributes->{p2}};
    }
}

role hasActionParamsDeep {
    has 'p_deep' => (is=>'ro', lazy_build=>1);
    method _build_p_deep {
        join ',', @{$self->attributes->{p_deep}};
    }
}

controller ::Controller::ActionParams {

    action base
    under '/base'
    as 'actionparams';

    action first under base
    with hasActionParams(p1=>100,p2=>101)
    is final {
        my $p1 = $ctx->controller->action_for('first')->p1;
        my $p2 = $ctx->controller->action_for('first')->p2;
        $ctx->response->body("action_args_first: $p1,$p2");
    }

    action second under base
    with hasActionParams({p1=>200,p2=>201})
    is final {
        my $p1 = $ctx->controller->action_for('second')->p1;
        my $p2 = $ctx->controller->action_for('second')->p2;
        $ctx->response->body("action_args_second: $p1,$p2");
    }

    action third under base
    with hasActionParams(
        p1=>300,
        p2=>301,
    ) is final {
        my $p1 = $ctx->controller->action_for('third')->p1;
        my $p2 = $ctx->controller->action_for('third')->p2;
        $ctx->response->body("action_args_third: $p1,$p2");
    }

    action forth under base
    with (
        hasActionParams(p1=>400,p2=>401), 
        hasActionParams(p1=>1,p2=>2, p0=>3)
    ) is final {
        my $action = $ctx->controller->action_for('forth');
        my $p1 = $action->p1;
        my $p2 = $action->p2;
        $ctx->response->body("action_args_forth: $p1,$p2");
    }

    action first_app_ns under base
    with hasActionParams_AppNS(p1=>100,p2=>101)
    is final {
        my $p1 = $ctx->controller->action_for('first')->p1;
        my $p2 = $ctx->controller->action_for('first')->p2;
        $ctx->response->body("action_args_first: $p1,$p2");
    }

    action first_cat_ns under base
    with hasActionParams_CatNS(p1=>100,p2=>101)
    is final {
        my $p1 = $ctx->controller->action_for('first')->p1;
        my $p2 = $ctx->controller->action_for('first')->p2;
        $ctx->response->body("action_args_first: $p1,$p2");
    }

    action check_deep under base
    with hasActionParamsDeep(p_deep=>{a=>1,b=>2}) is final {
        my $action = $ctx->controller->action_for('check_deep');
        my $p_deep = $action->p_deep;
        ## $ctx->log->_dump($action->attributes);
        $ctx->response->body("action_args_deep: $p_deep");
    }


}

