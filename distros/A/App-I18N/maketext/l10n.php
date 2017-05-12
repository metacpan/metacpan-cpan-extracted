<?




/* gettext helper function


    Usage:

        echo __("Text");

        echo __("Text %1" , 123);

        echo __("Text %2 %1" , 123 , 234);

 */
function __()
{
    $args = func_get_args();
    $msg = _( array_shift( $args ) );
    $id = 1;
    foreach( $args as $arg ) {
        $msg = str_replace( "%$id" , $arg , $msg );
        $id++;
    }
    return $msg;
}


// helper l10n class

class L10N {
    protected $cur_lang = array();
    protected $a_langs = array();
    protected $localedir;
    protected $domain;
    protected $default_lang;

    function deflang( $lang )
    {
        $this->default_lang = $lang;
        return $this;
    }

    function init( $force_lang = null  )
    {
        $lang = null;
        if( $force_lang ) {
            $lang = $force_lang;
        } else if( isset($_GET['locale']) ) { 
            $lang = $_GET['locale'];
        } else if( isset($_REQUEST['locale']) ) {
            $lang = $_REQUEST['locale'];
        } else if( isset( $_COOKIE['locale'] ) ) {
            $lang = $_COOKIE['locale'];
        }

        if( $lang == null ) {
            $lang = $this->default_lang;
        }
        $this->speak( $lang );
        return $this;
    }


    // set current language
    function speak( $lang )
    {
        $this->cur_lang = $lang;
        setcookie("locale", $lang , time() + 60 * 60 * 24 * 30 );

        $_REQUEST['locale'] = $lang;
        $_COOKIE['locale'] = $lang;

        $this->gettext();
        return $this;
    }

    function is_speaking( $lang )
    {
        return $this->cur_lang == $lang;
    }


    function speaking()
    {
        return $this->cur_lang;
    }

    // get available language list
    function langs()
    {
        return $this->a_langs;
    }

    function set_list( $list )
    {
        $this->a_langs = $list;
    }

    function add( $lang , $name )
    {
        $this->a_langs[ $lang ] = $name;
        return $this;
    }

    function remove( $lang )
    {
        unset( $this->a_langs[ $lang ] );
        return $this;
    }

    // get language name from language hash
    function name( $lang )
    {
        return @$this->a_langs[ $lang ];
    }

    function domain( $domain )
    {
        $this->domain = $domain;
        return $this;
    }

    function localedir( $dir )
    {
        $this->localedir = $dir;
        return $this;
    }

    function gettext( $textdomain = null , $localedir = null )
    {
        if( $textdomain == null )
            $textdomain = $this->domain;

        if( $localedir == null )
            $localedir = $this->localedir;
        if( $localedir == null ) 
            $localedir = dirname(__FILE__) . '/' . 'locale';

        $lang = $this->cur_lang;

        putenv("LANG=$lang");
        setlocale(LC_MESSAGES, $lang );

        bindtextdomain( $textdomain, $localedir );
        bind_textdomain_codeset( $textdomain, 'UTF-8');
        textdomain( $textdomain );
        return $this;
    }
}

function l10n()
{
    global $l10n;
    if( $l10n == null ) {
        $l10n = new L10N();
    }
    return $l10n;
}

function current_lang()
{
    return l10n()->speaking();
}


?>
