<?php

#require_once "$_SERVER[AUTH_ANY_ROOT]/google/common.php";
require_once "common.php";

session_start();

function getOpenIDURL() {
    // This is Google auth so use the Google openid_identifier
    return 'https://www.google.com/accounts/o8/id';
}

function getTrustRoot() {
    $defaultTrustRoot =  sprintf("%s://%s:%s%s/",
                                 getScheme(), $_SERVER['SERVER_NAME'],
                                 $_SERVER['SERVER_PORT'],
                                 dirname($_SERVER['PHP_SELF']));
    return $defaultTrustRoot;
}

function redirect_to_provider() {
    $openid = getOpenIDURL();
    $consumer = getConsumer();

    // Begin the OpenID authentication process.
    $auth_request = $consumer->begin($openid);

    // No auth request means we can't begin OpenID.
    if (!$auth_request) {
        abortSignin("Could not connect to provider - \$consumer->begin($openid) failed");
    }

    // Create attribute request object
    // See http://code.google.com/apis/accounts/docs/OpenID.html#Parameters for parameters
    // Usage: make($type_uri, $count=1, $required=false, $alias=null)
    $attribute[] = Auth_OpenID_AX_AttrInfo::make('http://axschema.org/contact/email',2,1, 'email');
    // $attribute[] = Auth_OpenID_AX_AttrInfo::make('http://axschema.org/namePerson/first',1,1, 'firstname');
    // $attribute[] = Auth_OpenID_AX_AttrInfo::make('http://axschema.org/namePerson/last',1,1, 'lastname');
    
    // Create AX fetch request
    $ax = new Auth_OpenID_AX_FetchRequest;
    
    // Add attributes to AX fetch request
    foreach ($attribute as $attr) {
            $ax->add($attr);
    }
    
    // Add AX fetch request to authentication request
    $auth_request->addExtension($ax);

    $policy_uris;
    $max_auth_age = 1; // 1 second. Forces login with each request
    $pape_request = new Auth_OpenID_PAPE_Request($policy_uris, $max_auth_age);
    $auth_request->addExtension($pape_request);

    // Redirect the user to the OpenID server for authentication.
    // Store the token for this authentication so we can verify the
    // response.

    $redirect_url = $auth_request->redirectURL(getTrustRoot(),
                                               getReturnTo());

    // If the redirect URL can't be built, display an error
    // message.
    if (Auth_OpenID::isFailure($redirect_url)) {
        abortSignin("Could not connect to provider with '$redirect_url'");
    } else {
        // Send redirect.
        header("Location: " . $redirect_url);
    }
}

redirect_to_provider();

?>
