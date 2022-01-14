class:MasterModel
  class_description="Master description"
  license=LGPL
  author:="dod@foo.com"
  copyright:="2011 dod"
  element:std_id
    type=hash
    index_type=string
    cargo
      type=node
      config_class_name=MasterModel::SlaveZ - -
  element:integer_with_warn_if
    type=leaf
    value_type=integer
    warn_if:warn_test
      code="defined $_ && $_ < 9;"
      msg="should be greater than 9"
      fix="$_ = 10;" - -
  element:lista
    type=list
    cargo
      type=leaf
      value_type=string - -
  element:listb
    type=list
    cargo
      type=leaf
      value_type=string - -
  element:ac_list
    type=list
    auto_create_ids=3
    cargo
      type=leaf
      value_type=string - -
  element:list_XLeds
    type=list
    cargo
      type=leaf
      value_type=integer
      min=1
      max=3 - -
  element:hash_a
    type=hash
    level=important
    index_type=string
    cargo
      type=leaf
      value_type=string - -
  element:hash_b
    type=hash
    index_type=string
    cargo
      type=leaf
      value_type=string - -
  element:olist
    type=list
    cargo
      type=node
      config_class_name=MasterModel::SlaveZ - -
  element:tree_macro
    type=leaf
    value_type=enum
    choice:=XY,XZ,mXY
    help:XY="XY help"
    help:XZ="XZ help"
    help:mXY="mXY help"
    level=important
    summary="macro parameter for tree"
    description="controls behavior of other elements" -
  element:warp_el
    type=warped_node
    morph=1
    config_class_name=MasterModel::SlaveY
    warp
      follow:f1="! tree_macro"
      rules:"$f1 eq 'mXY'"
        config_class_name=MasterModel::SlaveY -
      rules:"$f1 eq 'XZ'"
        config_class_name=MasterModel::SlaveZ - - -
  element:tolerant_node
    type=node
    config_class_name=MasterModel::TolerantNode -
  element:slave_y
    type=node
    config_class_name=MasterModel::SlaveY -
  element:string_with_def
    type=leaf
    value_type=string
    default="yada yada" -
  element:a_string
    type=leaf
    value_type=string
    mandatory=1 -
  element:int_v
    type=leaf
    value_type=integer
    min=5
    max=15
    default=10
    level=important -
  element:my_check_list
    type=check_list
    refer_to="- hash_a + ! hash_b" -
  element:ordered_checklist
    type=check_list
    choice:=A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z
    ordered=1
    help:A="A help"
    help:E="E help" -
  element:my_reference
    type=leaf
    value_type=reference
    refer_to="- hash_a + ! hash_b" -
  element:lot_of_checklist
    type=node
    config_class_name=MasterModel::CheckListExamples -
  element:warped_values
    type=node
    config_class_name=MasterModel::WarpedValues -
  element:warped_id
    type=node
    config_class_name=MasterModel::WarpedId -
  element:hash_id_of_values
    type=node
    config_class_name=MasterModel::HashIdOfValues -
  element:deprecated_p
    type=leaf
    value_type=enum
    choice:=cds,perl,ini,custom
    status=deprecated
    description="deprecated_p is replaced by new_from_deprecated" -
  element:new_from_deprecated
    type=leaf
    value_type=enum
    migrate_from
      variables:old="- deprecated_p"
      formula=$replace{$old}
      replace:cds=cds_file
      replace:ini=ini_file
      replace:perl=perl_file -
    choice:=cds_file,perl_file,ini_file,custom -
  element:old_url
    type=leaf
    value_type=uniline
    status=deprecated -
  element:host
    type=leaf
    value_type=uniline
    migrate_from
      variables:old="- old_url"
      formula="$old =~ m!http://([\w\.]+)!; $1 ;"
      use_eval=1 - -
  element:reference_stuff
    type=node
    config_class_name=MasterModel::References -
  element:match
    type=leaf
    value_type=string
    match=^foo\d{2}$ -
  element:prd_match
    type=leaf
    value_type=string
    grammar="token (oper token)(s?)
                                            oper: 'and' | 'or'
                                            token: 'Apache' | 'CC-BY' | 'Perl'
                                           " -
  element:warn_if
    type=leaf
    value_type=string
    warn_if_match:foo
      fix="$_ = uc;" - -
  element:warn_unless
    type=leaf
    value_type=string
    warn_unless_match:foo
      fix="$_ = \"foo\".$_;" - -
  element:list_with_migrate_values_from
    type=list
    migrate_values_from="- lista"
    cargo
      type=leaf
      value_type=string - -
  element:hash_with_migrate_keys_from
    type=hash
    migrate_keys_from="- hash_a"
    index_type=string
    cargo
      type=leaf
      value_type=string - -
  element:assert_leaf
    type=leaf
    value_type=string
    assert:assert_test
      code="defined $_ and /\w/"
      msg="must not be empty"
      fix="$_ = \"foobar\";" - -
  element:leaf_with_warn_unless
    type=leaf
    value_type=string
    warn_unless:warn_test
      code="defined $_ and /\w/"
      msg="should not be empty"
      fix="$_ = \"foobar\";" - -
  element:Source
    type=leaf
    value_type=string
    migrate_from
      variables:old="- Upstream-Source"
      variables:older="- Original-Source-Location"
      formula="$old || $older ;"
      use_eval=1
      undef_is='' - -
  element:Upstream-Source
    type=leaf
    value_type=string
    status=deprecated -
  element:Original-Source-Location
    type=leaf
    value_type=string
    status=deprecated -
  element:list_with_warn_duplicates
    type=list
    duplicates=warn
    cargo
      type=leaf
      value_type=string - -
  element:list_with_allow_duplicates
    type=list
    cargo
      type=leaf
      value_type=string - -
  element:list_with_forbid_duplicates
    type=list
    duplicates=forbid
    cargo
      type=leaf
      value_type=string - -
  element:list_with_suppress_duplicates
    type=list
    duplicates=suppress
    cargo
      type=leaf
      value_type=string - -
  rw_config
    backend=cds_file
    config_dir=conf_data
    file=mymaster.cds
    auto_create=1 - -
class:MasterModel::CheckListExamples
  element:my_hash
    type=hash
    index_type=string
    cargo
      type=leaf
      value_type=string - -
  element:my_hash2
    type=hash
    index_type=string
    cargo
      type=leaf
      value_type=string - -
  element:my_hash3
    type=hash
    index_type=string
    cargo
      type=leaf
      value_type=string - -
  element:choice_list
    type=check_list
    choice:=A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z
    help:A="A help"
    help:E="E help" -
  element:choice_list_with_default
    type=check_list
    choice:=A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z
    default_list=A,D
    help:A="A help"
    help:E="E help" -
  element:choice_list_with_upstream_default_list
    type=check_list
    choice:=A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z
    upstream_default_list=A,D
    help:A="A help"
    help:E="E help" -
  element:macro
    type=leaf
    value_type=enum
    choice:=AD,AH -
  element:warped_choice_list
    type=check_list
    warp
      follow:f1="- macro"
      rules:"$f1 eq 'AH'"
        choice:=A,B,C,D,E,F,G,H -
      rules:"$f1 eq 'AD'"
        choice:=A,B,C,D
        default_list=A,B - - -
  element:refer_to_list
    type=check_list
    refer_to="- my_hash" -
  element:refer_to_2_list
    type=check_list
    refer_to="- my_hash + - my_hash2   + - my_hash3" -
  element:refer_to_check_list_and_choice
    type=check_list
    computed_refer_to
      variables:var="- indirection "
      formula="- refer_to_2_list + - $var" -
    choice:=A1,A2,A3 -
  element:indirection
    type=leaf
    value_type=string - -
class:MasterModel::HashIdOfValues
  element:plain_hash
    type=hash
    index_type=integer
    cargo
      type=leaf
      value_type=string - -
  element:hash_with_auto_created_id
    type=hash
    auto_create_keys:=yada
    index_type=string
    cargo
      type=leaf
      value_type=string - -
  element:hash_with_several_auto_created_id
    type=hash
    auto_create_keys:=x,y,z
    index_type=string
    cargo
      type=leaf
      value_type=string - -
  element:hash_with_default_id
    type=hash
    default_keys:=yada
    index_type=string
    cargo
      type=leaf
      value_type=string - -
  element:hash_with_default_id_2
    type=hash
    default_keys:=yada
    index_type=string
    cargo
      type=leaf
      value_type=string - -
  element:hash_with_several_default_keys
    type=hash
    default_keys:=x,y,z
    index_type=string
    cargo
      type=leaf
      value_type=string - -
  element:hash_follower
    type=hash
    follow_keys_from="- hash_with_several_auto_created_id"
    index_type=string
    cargo
      type=leaf
      value_type=string - -
  element:hash_with_allow
    type=hash
    allow_keys:=foo,bar,baz
    index_type=string
    cargo
      type=leaf
      value_type=string - -
  element:hash_with_allow_from
    type=hash
    allow_keys_from="- hash_with_several_auto_created_id"
    index_type=string
    cargo
      type=leaf
      value_type=string - -
  element:ordered_hash
    type=hash
    ordered=1
    index_type=string
    cargo
      type=leaf
      value_type=string - - -
class:MasterModel::RSlave
  element:recursive_slave
    type=hash
    index_type=string
    cargo
      type=node
      config_class_name=MasterModel::RSlave - -
  element:big_compute
    type=hash
    index_type=string
    cargo
      type=leaf
      value_type=string
      compute
        variables:m="!  macro"
        variables:up=-
        formula="macro is $m, my idx: &index, my element &element, upper element &element($up), up idx &index($up)" - - -
  element:big_replace
    type=leaf
    value_type=string
    compute
      variables:up=-
      formula="trad idx $replace{&index($up)}"
      replace:l1=level1
      replace:l2=level2 - -
  element:macro_replace
    type=hash
    index_type=string
    cargo
      type=leaf
      value_type=string
      compute
        variables:m="!  macro"
        formula="trad macro is $replace{$m}"
        replace:A=macroA
        replace:B=macroB
        replace:C=macroC - - - -
class:MasterModel::References
  element:host
    type=hash
    index_type=string
    cargo
      type=node
      config_class_name=MasterModel::References::Host - -
  element:lan
    type=hash
    index_type=string
    cargo
      type=node
      config_class_name=MasterModel::References::Lan - -
  element:host_and_choice
    type=leaf
    value_type=reference
    computed_refer_to
      formula="- host " -
    choice:=foo,bar -
  element:dumb_list
    type=list
    cargo
      type=leaf
      value_type=string - -
  element:refer_to_list_enum
    type=leaf
    value_type=reference
    refer_to="- dumb_list" - -
class:MasterModel::References::Host
  element:if
    type=hash
    index_type=string
    cargo
      type=node
      config_class_name=MasterModel::References::If - -
  element:trap
    type=leaf
    value_type=string - -
class:MasterModel::References::If
  element:ip
    type=leaf
    value_type=string - -
class:MasterModel::References::Lan
  element:node
    type=hash
    index_type=string
    cargo
      type=node
      config_class_name=MasterModel::References::Node - - -
class:MasterModel::References::Node
  element:host
    type=leaf
    value_type=reference
    refer_to="- host" -
  element:if
    type=leaf
    value_type=reference
    computed_refer_to
      variables:h="- host"
      formula="  - host:$h if " - -
  element:ip
    type=leaf
    value_type=string
    compute
      variables:card="- if"
      variables:h="- host"
      variables:ip="- host:$h if:$card ip"
      formula=$ip - - -
class:MasterModel::Slave
  element:X
    type=leaf
    value_type=enum
    choice:=Av,Bv,Cv
    warp
      follow:f1="- - macro"
      rules:"$f1 eq 'B'"
        default=Bv -
      rules:"$f1 eq 'A'"
        default=Av - - -
  element:Y
    type=leaf
    value_type=enum
    choice:=Av,Bv,Cv
    warp
      follow:f1="- - macro"
      rules:"$f1 eq 'B'"
        default=Bv -
      rules:"$f1 eq 'A'"
        default=Av - - -
  element:Z
    type=leaf
    value_type=enum
    choice:=Av,Bv,Cv
    warp
      follow:f1="- - macro"
      rules:"$f1 eq 'B'"
        default=Bv -
      rules:"$f1 eq 'A'"
        default=Av - - -
  element:recursive_slave
    type=hash
    index_type=string
    cargo
      type=node
      config_class_name=MasterModel::RSlave - -
  element:W
    type=leaf
    value_type=enum
    level=hidden
    warp
      follow:f1="- - macro"
      rules:"$f1 eq 'B'"
        choice:=Av,Bv,Cv
        default=Bv
        level=normal -
      rules:"$f1 eq 'A'"
        choice:=Av,Bv,Cv
        default=Av
        level=normal - - -
  element:Comp
    type=leaf
    value_type=string
    compute
      variables:m="- - macro"
      formula="macro is $m" - - -
class:MasterModel::SlaveY
  element:std_id
    type=hash
    index_type=string
    cargo
      type=node
      config_class_name=MasterModel::SlaveZ - -
  element:sub_slave
    type=node
    config_class_name=MasterModel::SubSlave -
  element:warp2
    type=warped_node
    morph=1
    config_class_name=MasterModel::SubSlave
    warp
      follow:f1="! tree_macro"
      rules:"$f1 eq 'mXY'"
        config_class_name=MasterModel::SubSlave2 -
      rules:"$f1 eq 'XZ'"
        config_class_name=MasterModel::SubSlave2 - - -
  element:Y
    type=leaf
    value_type=enum
    choice:=Av,Bv,Cv -
  include:=MasterModel::X_base_class -
class:MasterModel::SlaveZ
  element:Z
    type=leaf
    value_type=enum
    choice:=Av,Bv,Cv -
  element:DX
    type=leaf
    value_type=enum
    choice:=Av,Bv,Cv,Dv
    default=Dv -
  include:=MasterModel::X_base_class -
class:MasterModel::SubSlave
  element:aa
    type=leaf
    value_type=string -
  element:ab
    type=leaf
    value_type=string -
  element:ac
    type=leaf
    value_type=string -
  element:ad
    type=leaf
    value_type=string -
  element:sub_slave
    type=node
    config_class_name=MasterModel::SubSlave2 - -
class:MasterModel::SubSlave2
  element:aa2
    type=leaf
    value_type=string -
  element:ab2
    type=leaf
    value_type=string -
  element:ac2
    type=leaf
    value_type=string -
  element:ad2
    type=leaf
    value_type=string -
  element:Z
    type=leaf
    value_type=string - -
class:MasterModel::TolerantNode
  element:id
    type=leaf
    value_type=uniline -
  accept:"list.*"
    type=list
    cargo
      type=leaf
      value_type=string - -
  accept:"str.*"
    type=leaf
    value_type=uniline - -
class:MasterModel::WarpedId
  element:macro
    type=leaf
    value_type=enum
    choice:=A,B,C -
  element:version
    type=leaf
    value_type=integer
    default=1 -
  element:warped_hash
    type=hash
    max_nb=3
    warp
      follow:f1="- macro"
      rules:"$f1 eq 'B'"
        max_nb=2 -
      rules:"$f1 eq 'A'"
        max_nb=1 - -
    index_type=integer
    cargo
      type=node
      config_class_name=MasterModel::WarpedIdSlave - -
  element:multi_warp
    type=hash
    min_index=0
    max_index=3
    default_keys:=0,1,2,3
    warp
      follow:f0="- version"
      follow:f1="- macro"
      rules:"$f0 eq '2' and $f1 eq 'C'"
        max_index=7
        default_keys:=0,1,2,3,4,5,6,7 -
      rules:"$f0 eq '2' and $f1 eq 'A'"
        max_index=7
        default_keys:=0,1,2,3,4,5,6,7 - -
    index_type=integer
    cargo
      type=node
      config_class_name=MasterModel::WarpedIdSlave - -
  element:hash_with_warped_value
    type=hash
    level=hidden
    warp
      follow:f1="- macro"
      rules:"$f1 eq 'A'"
        level=normal - -
    index_type=string
    cargo
      type=leaf
      value_type=string
      warp
        follow:f1="- macro"
        rules:"$f1 eq 'A'"
          default="dumb string" - - - -
  element:multi_auto_create
    type=hash
    min_index=0
    max_index=3
    auto_create_keys:=0,1,2,3
    warp
      follow:f0="- version"
      follow:f1="- macro"
      rules:"$f0 eq '2' and $f1 eq 'C'"
        max_index=7
        auto_create_keys:=0,1,2,3,4,5,6,7 -
      rules:"$f0 eq '2' and $f1 eq 'A'"
        max_index=7
        auto_create_keys:=0,1,2,3,4,5,6,7 - -
    index_type=integer
    cargo
      type=node
      config_class_name=MasterModel::WarpedIdSlave - - -
class:MasterModel::WarpedIdSlave
  element:X
    type=leaf
    value_type=enum
    choice:=Av,Bv,Cv -
  element:Y
    type=leaf
    value_type=enum
    choice:=Av,Bv,Cv -
  element:Z
    type=leaf
    value_type=enum
    choice:=Av,Bv,Cv - -
class:MasterModel::WarpedValues
  element:get_element
    type=leaf
    value_type=enum
    choice:=m_value_element,compute_element -
  element:where_is_element
    type=leaf
    value_type=enum
    choice:=get_element -
  element:macro
    type=leaf
    value_type=enum
    choice:=A,B,C,D -
  element:macro2
    type=leaf
    value_type=enum
    level=hidden
    warp
      follow:f1="- macro"
      rules:"$f1 eq 'B'"
        choice:=A,B,C,D
        level=normal - - -
  element:m_value
    type=leaf
    value_type=enum
    warp
      follow:m="- macro"
      rules:"$m eq \"A\" or $m eq \"D\""
        choice:=Av,Bv
        help:Av="Av help" -
      rules:"$m eq \"B\""
        choice:=Bv,Cv
        help:Bv="Bv help" -
      rules:"$m eq \"C\""
        choice:=Cv
        help:Cv="Cv help" - - -
  element:m_value_old
    type=leaf
    value_type=enum
    warp
      follow:f1="- macro"
      rules:"$f1 eq 'A' or $f1 eq 'D'"
        choice:=Av,Bv
        help:Av="Av help" -
      rules:"$f1 eq 'B'"
        choice:=Bv,Cv
        help:Bv="Bv help" -
      rules:"$f1 eq 'C'"
        choice:=Cv
        help:Cv="Cv help" - - -
  element:compute
    type=leaf
    value_type=string
    compute
      variables:m="-  macro"
      formula="macro is $m, my element is &element" - -
  element:var_path
    type=leaf
    value_type=string
    compute
      variables:s="- $where"
      variables:v="- $replace{$s}"
      variables:where="- where_is_element"
      formula="get_element is $replace{$s}, indirect value is '$v'"
      replace:compute_element=compute
      replace:m_value_element=m_value -
    mandatory=1 -
  element:class
    type=hash
    index_type=string
    cargo
      type=leaf
      value_type=string - -
  element:warped_out_ref
    type=leaf
    value_type=reference
    refer_to="- class"
    level=hidden
    warp
      follow:m="- macro"
      follow:m2="- macro2"
      rules:"$m eq \"A\" or $m2 eq \"A\""
        level=normal - - -
  element:bar
    type=node
    config_class_name=MasterModel::Slave -
  element:foo
    type=node
    config_class_name=MasterModel::Slave -
  element:foo2
    type=node
    config_class_name=MasterModel::Slave - -
class:MasterModel::X_base_class
  include:=MasterModel::X_base_class2 -
class:MasterModel::X_base_class2
  class_description="rather dummy class to check include"
  element:X
    type=leaf
    value_type=enum
    choice:=Av,Bv,Cv - -
class:Master::Created
  element:created1
    type=leaf
    value_type=number -
  element:created2
    type=leaf
    value_type=uniline - -
application:goner
  model=MasterModel
  category=application
  allow_config_file_override=1 -
application:master
  model=MasterModel
  category=application
  allow_config_file_override=1 - -
