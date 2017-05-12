<?php

#       #       #       #
#
# BabelKit.php
#
# Interface to a Universal Multilingual Code Table.
#
# Copyright (C) 2003 John Gorman <jgorman@webbysoft.com>
# http://www.webbysoft.com/babelkit
#
### Public methods:
#
# $bk = new BabelKit($dbh, $param=array());
#               'table' => 'bk_code'
#
### Get code descriptions safe for HTML display:
# 
# $str = $bk->desc(   $code_set, $code_lang, $code_code);
# $str = $bk->ucfirst($code_set, $code_lang, $code_code);
# $str = $bk->ucwords($code_set, $code_lang, $code_code);
#
### Get code descriptions not safe for HTML display:
#
# $str = $bk->render($code_set, $code_lang, $code_code);
# $str = $bk->data(  $code_set, $code_lang, $code_code);
# $str = $bk->param( $code_set, $code_code)
#
### HTML select common options:
#
#               'var_name'      => 'start_day'
#               'value'         => $start_day
#               'default'       => 1
#               'subset'        => array( 1, 2, 3, 4, 5 )
#               'options'       => 'onchange="submit()"'
#
### HTML select single value methods:
# 
# $str = $bk->select($code_set, $code_lang, $param=array());
#               'select_prompt' => "Code set description?"
#               'blank_prompt'  => "None"
#
# $str = $bk->radio($code_set, $code_lang, $param=array());
#               'blank_prompt'  => "None"
#               'sep'           => "<br>\n"
#
### HTML select multiple value methods:
#
# $str = $bk->multiple($code_set, $code_lang, $param=array());
#               'size'          => 10
#
# $str = $bk->checkbox($code_set, $code_lang, $param=array());
#               'sep'           => "<br>\n"
#
### Code sets:
#
# $rows = $bk->lang_set($code_set, $code_lang);
# $rows = $bk->full_set($code_set, $code_lang);
#
### Code table updates:
# 
# $bk->slave($code_set, $code_code, $code_desc);
#
# $bk->remove($code_set, $code_code);
#
# list($code_desc, $code_order, $code_flag) =
#   $bk->get($code_set, $code_lang, $code_code);
#
# $bk->put($code_set, $code_lang, $code_code, $code_desc,
#          $code_order = 0, $code_flag = '');
#
#       #       #       #

### Public methods:

class BabelKit {

    var $dbh;           # Library handle.
    var $lib_type;      # Library type: pear | adodb | phplib.
    var $table;         # Code table name.
    var $native;        # Native language.

    function BabelKit($dbh, $param=array()) {

        $this->dbh = $dbh;
        if (!is_object($dbh))
            die('BabelKit($dbh): $dbh is not an object');
        if (isset($dbh->databaseType))
            $this->lib_type = 'adodb';
        elseif (isset($dbh->Database))
            $this->lib_type = 'phplib';
        elseif (isset($dbh->connection))
            $this->lib_type = 'pear';
        else
            die('BabelKit($dbh): $dbh is not a pear/adodb/phplib handle');

        $this->table = $param['table'] ? $param['table'] : 'bk_code';

        $this->native = $this->_find_native();
        if (!$this->native)
            die("BabelKit(): unable to determine native language. " .
                "Check table '$this->table' for code_admin/code_admin record.");
    }

### Get code descriptions safe for HTML display:

    #       #       #       #
    # Get a code description safe for html display.
    # Fill missing translations with the native desc or code.
    #
    function desc($code_set, $code_lang, $code_code) {
        return htmlspecialchars(
            $this->render($code_set, $code_lang, $code_code)
        );
    }

    #       #       #       #
    # Get a code description with the First letter capitalized.
    #
    function ucfirst($code_set, $code_lang, $code_code) {
        return ucfirst( $this->desc($code_set, $code_lang, $code_code) );
    }

    #       #       #       #
    # Get a code description with Each Word Capitalized.
    #
    function ucwords($code_set, $code_lang, $code_code) {
        return ucwords( $this->desc($code_set, $code_lang, $code_code) );
    }

### Get code descriptions not safe for HTML display:

    #       #       #       #
    # Get a raw code description *not* safe for html display.
    # Fill missing translations with the native desc or code.
    #
    function render($code_set, $code_lang, $code_code) {
        $code_desc = $this->data($code_set, $code_lang, $code_code);
        if ($code_desc == '') {
            $code_desc = $this->data($code_set, $this->native, $code_code);
            if ($code_desc == '')
                $code_desc = $code_code;
        }
        return $code_desc;
    }

    #       #       #       #
    # Get a raw code_desc, *not* safe for html display.
    #
    function data($code_set, $code_lang, $code_code) {
        $result = $this->_query("
            select  code_desc
            from    $this->table
            where   code_set  = '$code_set'
            and     code_lang = '$code_lang'
            and     code_code = '$code_code'
        ");
        return $result[0][0];
    }

    #       #       #       #
    # Get a raw config parameter (native).
    #
    function param($code_set, $code_code) {
        return $this->data($code_set, $this->native, $code_code);
    }

### HTML select single value methods:

    #       #       #       #
    # Create an html form selection dropdown from a code set.
    #
    function select($code_set, $code_lang, $param=array()) {

        $var_name      = $param['var_name'];
        $value         = $param['value'];
        $default       = $param['default'];
        $subset        = $param['subset'];
        $options       = $param['options'];
        $select_prompt = $param['select_prompt'];
        $blank_prompt  = $param['blank_prompt'];

        # Variable name.
        if (!$var_name) $var_name = $code_set;
        if (!isset($value)) {
            $value = $_POST ? $_POST[$var_name] : $_GET[$var_name];
        }
        if (!isset($value)) $value = $default;
        if (is_array($subset)) {
            $Subset = array();
            foreach ( $subset as $val ) $Subset[$val] = 1;
        }
        if ($options) $options = " $options";

        # Drop down box.
        $select = "<select name=\"$var_name\"$options>\n";

        # Blank options.
        $selected = '';
        if ($value == '') {
            if ($select_prompt == '')
                $select_prompt =
                    $this->ucwords('code_set', $code_lang, $code_set).'?';
            $select .= "<option value=\"\" selected>$select_prompt\n";
            $selected = 1;
        } elseif ($blank_prompt <> '') {
            $select .= "<option value=\"\">$blank_prompt\n";
        }

        # Show code set options.
        $set_list = $this->full_set($code_set, $code_lang);
        foreach ( $set_list as $row ) {
            list($code_code, $code_desc) = $row;
            if ($Subset && !$Subset[$code_code] && $code_code <> $value)
                continue;
            $code_desc = htmlspecialchars(ucfirst($code_desc));

            if ($code_code == $value) {
                $selected = 1;
                $select .= "<option value=\"$code_code\" selected>$code_desc\n";
            } elseif ($row[3] <> 'd') {
                $select .= "<option value=\"$code_code\">$code_desc\n";
            }
        }

        # Show a missing value.
        if (!$selected) {
            $select .= "<option value=\"$value\" selected>$value\n";
        }

        $select .= "</select>\n";
        return $select;
    }

    #       #       #       #
    # Create an html form radio box from a code set.
    #
    function radio($code_set, $code_lang, $param=array()) {

        $var_name     = $param['var_name'];
        $value        = $param['value'];
        $default      = $param['default'];
        $subset       = $param['subset'];
        $options       = $param['options'];
        $blank_prompt = $param['blank_prompt'];
        $sep          = $param['sep'];

        # Variable name.
        if (!$var_name) $var_name = $code_set;
        if (!isset($value)) {
            $value = $_POST ? $_POST[$var_name] : $_GET[$var_name];
        }
        if (!isset($value)) $value = $default;
        if (is_array($subset)) {
            $Subset = array();
            foreach ( $subset as $val ) $Subset[$val] = 1;
        }
        if ($options) $options = " $options";
        if (!isset($sep)) $sep = "<br>\n";

        # Blank options.
        if ($value == '') {
            $selected = 1;
            if ($blank_prompt <> '') {
                $select .= "<input type=\"radio\" name=\"$var_name\"$options";
                $select .= " value=\"\" checked>$blank_prompt";
            }
        } else {
            if ($blank_prompt <> '') {
                $select .= "<input type=\"radio\" name=\"$var_name\"$options";
                $select .= " value=\"\">$blank_prompt";
            }
        }

        # Show code set options.
        $set_list = $this->full_set($code_set, $code_lang);
        foreach ( $set_list as $row ) {
            list($code_code, $code_desc) = $row;
            if ($Subset && !$Subset[$code_code] && $code_code <> $value)
                continue;
            $code_desc = htmlspecialchars(ucfirst($code_desc));
            if ( $code_code == $value ) {
                if ($select) $select .= $sep;
                $selected = 1;
                $select .= "<input type=\"radio\" name=\"$var_name\"$options";
                $select .= " value=\"$code_code\" checked>$code_desc";
            } elseif ($row[3] <> 'd') {
                if ($select) $select .= $sep;
                $select .= "<input type=\"radio\" name=\"$var_name\"$options";
                $select .= " value=\"$code_code\">$code_desc";
            }
        }

        # Show missing values.
        if (!$selected) {
            if ($select) $select .= $sep;
            $select .= "<input type=\"radio\" name=\"$var_name\"$options";
            $select .= " value=\"$value\" checked>$value";
        }

        return $select;
    }


### HTML select multiple value methods:

    #       #       #       #
    # Create an html form multiple select box from a code set.
    #
    function multiple($code_set, $code_lang, $param=array()) {

        $var_name = $param['var_name'];
        $value    = $param['value'];
        $default  = $param['default'];
        $subset   = $param['subset'];
        $options       = $param['options'];
        $size     = $param['size'];

        # Variable name.
        if (!$var_name) $var_name = $code_set;
        if (!isset($value)) {
            $value = $_POST ? $_POST[$var_name] : $_GET[$var_name];
        }
        if (!isset($value)) $value = $default;
        $Value = array();
        if (is_array($value)) {
            foreach ( $value as $val ) $Value[$val] = 1;
        } elseif ($value <> '') {
            $Value[$value] = 1;
        }
        if (is_array($subset)) {
            $Subset = array();
            foreach ( $subset as $val ) $Subset[$val] = 1;
        }
        if ($options) $options = " $options";

        # Select multiple box.
        $select = "<select multiple name=\"$var_name"."[]\"$options";
        if ($size) $select .= " size=\"$size\"";
        $select .= ">\n";

        # Show code set options.
        $set_list = $this->full_set($code_set, $code_lang);
        foreach ( $set_list as $row ) {
            list($code_code, $code_desc) = $row;
            if ($Subset && !$Subset[$code_code] && !$Value[$code_code])
                continue;
            $code_desc = htmlspecialchars(ucfirst($code_desc));
            if ( $Value[$code_code] ) {
                $select .= "<option value=\"$code_code\" selected>$code_desc\n";
                unset($Value[$code_code]);
            } elseif ($row[3] <> 'd') {
                $select .= "<option value=\"$code_code\">$code_desc\n";
            }
        }

        # Show missing values.
        foreach ( $Value as $code_code => $true ) {
            $select .= "<option value=\"$code_code\" selected>$code_code\n";
        }

        $select .= "</select>\n";
        return $select;
    }

    #       #       #       #
    # Create an html form checkbox from a code set.
    #
    function checkbox($code_set, $code_lang, $param=array()) {

        $var_name = $param['var_name'];
        $value    = $param['value'];
        $default  = $param['default'];
        $subset   = $param['subset'];
        $options  = $param['options'];
        $sep      = $param['sep'];

        # Variable name.
        if (!$var_name) $var_name = $code_set;
        if (!isset($value)) {
            $value = $_POST ? $_POST[$var_name] : $_GET[$var_name];
        }
        if (!isset($value)) $value = $default;
        $Value = array();
        if (is_array($value)) {
            foreach ( $value as $val ) $Value[$val] = 1;
        } elseif ($value <> '') {
            $Value[$value] = 1;
        }
        if (is_array($subset)) {
            $Subset = array();
            foreach ( $subset as $val ) $Subset[$val] = 1;
        }
        if ($options) $options = " $options";
        if (!isset($sep)) $sep = "<br>\n";

        # Show code set options.
        $set_list = $this->full_set($code_set, $code_lang);
        foreach ( $set_list as $row ) {
            list($code_code, $code_desc) = $row;
            if ($Subset && !$Subset[$code_code] && !$Value[$code_code])
                continue;
            $code_desc = htmlspecialchars(ucfirst($code_desc));
            if ( $Value[$code_code] ) {
                if ($select) $select .= $sep;
                $select .= "<input type=\"checkbox\" name=\"$var_name"."[]\"";
                $select .= "$options value=\"$code_code\" checked>$code_desc";
                unset($Value[$code_code]);
            } elseif ($row[3] <> 'd') {
                if ($select) $select .= $sep;
                $select .= "<input type=\"checkbox\" name=\"$var_name"."[]\"";
                $select .= "$options value=\"$code_code\">$code_desc";
            }
        }

        # Show missing values.
        foreach ( $Value as $code_code => $true ) {
            if ($select) $select .= $sep;
            $select .= "<input type=\"checkbox\" name=\"$var_name"."[]\"";
            $select .= "$options value=\"$code_code\" checked>$code_code";
        }

        return $select;
    }


### Code sets and queries:

    #       #       #       #
    # Get a language set array.
    #
    function lang_set($code_set, $code_lang) {
        return $this->_query("
            select  code_code,
                    code_desc,
                    code_order,
                    code_flag
            from    $this->table
            where   code_set = '$code_set'
            and     code_lang = '$code_lang'
            order by code_order, code_code
        ");
    }

    #       #       #       #
    # Get a full language set with missing translations in native.
    #
    function full_set($code_set, $code_lang) {
        $native = $this->lang_set($code_set, $this->native);
        if ($code_lang == $this->native) return $native;
        $other = $this->lang_set($code_set, $code_lang);
        $lookup = array();
        foreach ( $other as $row ) $lookup[$row[0]] = $row[1];
        foreach ( $native as $ord => $row ) {
            $code_desc = $lookup[$row[0]];
            if (isset($code_desc)) $native[$ord][1] = $code_desc;
        }
        return $native;
    }


### Code table updates:

    #       #       #       #
    # Add or update a slave code native description.
    #
    function slave($code_set, $code_code, $code_desc) {
        $old = $this->get($code_set, $this->native, $code_code);
        if ($old) {
            list($old_desc, $old_order, $old_flag ) = $old;
            if ($code_desc <> $old_desc) {
                $this->put($code_set, $this->native,  $code_code, $code_desc,
                        $old_order, $old_flag);
            }
        } else {
            $this->put($code_set, $this->native,  $code_code, $code_desc);
        }
    }

    #       #       #       #
    # Remove a code completely.
    #
    function remove($code_set, $code_code) {
        $this->_query("
            delete from $this->table
            where   code_set  = '$code_set'
            and     code_code = '$code_code'
        ");
    }

    #       #       #       #
    # Get code desc, order, and flag.
    #
    function get($code_set, $code_lang, $code_code) {
        $result = $this->_query("
            select  code_desc,
                    code_order,
                    code_flag
            from    $this->table
            where   code_set  = '$code_set'
            and     code_lang = '$code_lang'
            and     code_code = '$code_code'
        ");
        return $result[0];
    }

    #       #       #       #
    # Put a code.  Insert, update or delete as appropriate.
    #
    function put($code_set, $code_lang, $code_code, $code_desc,
                 $code_order = '', $code_flag = '') {

        # Get the existing code info, if any.
        $old = $this->get($code_set, $code_lang, $code_code);

        # Field work.
        if ($code_lang == $this->native) {
            if (  !$old and is_numeric($code_code) and
                ( is_null($code_order) or $code_order === '' ) ) {
                $code_order = $code_code;
            }
            $code_order = (int)$code_order;
        } else {
            $code_order = 0;
            $code_flag = '';
        }

        # Make it so: add, update, or delete.
        if ($old) {
            list( $old_desc, $old_order, $old_flag ) = $old;
            if ($code_desc <> '') {
                if ($code_desc  <> $old_desc ||
                    $code_order <> $old_order ||
                    $code_flag  <> $old_flag) {
                    $this->_update($code_set, $code_lang, $code_code,
                                $code_desc, $code_order, $code_flag);
                }
            }
            else {
                if ($code_lang == $this->native) {
                    $this->remove($code_set, $code_code);
                } else {
                    $this->_delete($code_set, $code_lang, $code_code);
                }
            }
        }
        elseif ($code_desc <> '') {
            $this->_insert($code_set, $code_lang, $code_code,
                        $code_desc, $code_order, $code_flag);
        }
    }


### Private methods:

    #       #       #       #
    # Find the native language.
    #
    function _find_native() {
        $result = $this->_query("
            select  code_lang
            from    $this->table
            where   code_set  = 'code_admin'
            and     code_code = 'code_admin'
        ");
        return $result[0][0];
    }

    #       #       #       #
    # Insert a code.
    #
    function _insert($code_set, $code_lang, $code_code,
                        $code_desc, $code_order, $code_flag) {
        $this->_query("
            insert into $this->table set
                code_set   = '$code_set',
                code_lang  = '$code_lang',
                code_code  = '$code_code',
                code_desc  = '$code_desc',
                code_order = '$code_order',
                code_flag  = '$code_flag'
        ");
    }

    #       #       #       #
    # Update a code.
    #
    function _update($code_set, $code_lang, $code_code,
                        $code_desc, $code_order, $code_flag) {
        $this->_query("
            update $this->table set
                    code_desc  = '$code_desc',
                    code_order = '$code_order',
                    code_flag  = '$code_flag'
            where   code_set   = '$code_set'
            and     code_lang  = '$code_lang'
            and     code_code  = '$code_code'
        ");
    }

    #       #       #       #
    # Delete a code.
    #
    function _delete($code_set, $code_lang, $code_code) {
        $this->_query("
            delete from $this->table
            where   code_set  = '$code_set'
            and     code_lang = '$code_lang'
            and     code_code = '$code_code'
        ");
    }

    #       #       #       #
    # Run a library independent query and return the result set.
    #
    function _query($query) {
        $result = array();

        if ($this->lib_type == 'pear') {
            $dbq = $this->dbh->query($query);
            if (DB::isError($dbq))
                die("BabelKit: " . $dbq->getMessage() . ". query($query)");
            if (is_object($dbq)) {
                while ($row = $dbq->fetchRow()) {
                    if (!is_array($row)) break;
                    $result[] = $row;
                }
                $dbq->free();
            }

        } elseif ($this->lib_type == 'adodb') {
            $rs = $this->dbh->Execute($query);
            if ($rs) {
                if ($rs->connection) {
                    $result = $rs->GetRows();
                    $rs->Close();
                }
            } else {
                die("BabelKit: " . $this->dbh->ErrorMsg() . ". query($query)");
            }

        } elseif ($this->lib_type == 'phplib') {
            $dbh = $this->dbh;
            $dbh->query($query);
            while ($dbh->next_record()) {
                $result[] = $dbh->Record;
            }
            $dbh->free();

        }

        return $result;
    }

}

?>
