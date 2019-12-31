from collections import OrderedDict
import copy
import os
import sys
import shutil
import importlib
import glob
import json

from dash.development.base_component import _explicitize_args
from dash.exceptions import NonExistentEventException
from ._all_keywords import python_keywords
from .base_component import Component

# TODO Follow the same structure of R package generation

# pylint: disable=unused-argument
def generate_class_string(typename, props, description, namespace):
    """Dynamically generate class strings to have nicely formatted docstrings,
    keyword arguments, and repr.

    Inspired by http://jameso.be/2013/08/06/namedtuple.html

    Parameters
    ----------
    typename
    props
    description
    namespace

    Returns
    -------
    string
    """
    # TODO _prop_names, _type, _namespace, and available_properties
    # can be modified by a Dash JS developer via setattr
    # TODO - Tab out the repr for the repr of these components to make it
    # look more like a hierarchical tree
    # TODO - Include "description" "defaultValue" in the repr and docstring
    #
    # TODO - Handle "required"
    #
    # TODO - How to handle user-given `null` values? I want to include
    # an expanded docstring like Dropdown(value=None, id=None)
    # but by templating in those None values, I have no way of knowing
    # whether a property is None because the user explicitly wanted
    # it to be `null` or whether that was just the default value.
    # The solution might be to deal with default values better although
    # not all component authors will supply those.

    filtered_props = filter_props(props)
    prop_keys = list(filtered_props.keys())
    string_attributes = ""
    for p in prop_keys:
        # TODO support wildcard attributes
        if  p[-1] != "*":
            string_attributes += "has '{}';\n".format(p)
    perl_package_name = _perl_package_name_from_shortname(namespace)
    common = "my $dash_namespace = '" + namespace + "';\n\nsub DashNamespace {\nreturn $dash_namespace;\n}\nsub _js_dist {\nreturn " + perl_package_name + "::_js_dist;\n}\n"
    return string_attributes + common

# TODO Refactor this methods to a class

def _perl_package_name_from_shortname(shortname):
    namespace_components = shortname.split("_")
    package_name = ""
    for namespace_component in namespace_components:
        if (len(package_name) > 0):
            package_name += "::"
        package_name += namespace_component.title()
    return package_name

def _perl_file_name_from_shortname(shortname):
    namespace_components = shortname.split("_")
    return namespace_components[-1].title() + ".pm"

def generate_perl_package_file(typename, props, description, namespace):
    """Generate a python class file (.py) given a class string.

    Parameters
    ----------
    typename
    props
    description
    namespace

    Returns
    -------
    """
    perl_base_package = _perl_package_name_from_shortname(namespace)
    package_name = perl_base_package + "::" + typename

    import_string =\
        "# AUTO GENERATED FILE - DO NOT EDIT\n\n" + \
        "package " + package_name + ";\n\n" + \
        "use " + perl_base_package + ";\n" + \
        "use Mojo::Base 'Dash::BaseComponent';\n\n"

    class_string = generate_class_string(
        typename,
        props,
        description,
        namespace
    )
    file_name = "{:s}.pm".format(typename)

    directory = os.path.join('Perl', namespace)
    if not os.path.exists(directory):
        os.makedirs(directory)

    file_path = os.path.join(directory, file_name)
    with open(file_path, 'w') as f:
        f.write(import_string)
        f.write(class_string)
        f.write("\n1;\n");

    print('Generated {}'.format(file_name))

def write_js_metadata(pkg_data, project_shortname, has_wildcards):
    """Write an internal (not exported) R function to return all JS
    dependencies as required by dash.

    Parameters
    ----------
    project_shortname = hyphenated string, e.g. dash-html-components

    Returns
    -------
    """
    file_name = "js_deps.json"

    sys.path.insert(0, os.getcwd())
    mod = importlib.import_module(project_shortname)

    alldist = { "_js_dist": getattr(mod, "_js_dist", []) ,
            "_css_dist": getattr(mod, "_css_dist", []) 
                }


    # the Perl source directory for the package won't exist on first call
    # create the Perl directory if it is missing
    if not os.path.exists("Perl"):
        os.makedirs("Perl")

    file_path = os.path.join("Perl", file_name)
    with open(file_path, "w") as f:
        #f.write(function_string)
        f.write(json.dumps(alldist, indent=4))
        if has_wildcards:
            f.write(wildcard_helper)

    # now copy over all JS dependencies from the (Python) components dir
    # the inst/lib directory for the package won't exist on first call
    # create this directory if it is missing
    deps_output_path = os.path.join('Perl', 'deps')
    if os.path.exists(deps_output_path):
        shutil.rmtree(deps_output_path)

    os.makedirs(deps_output_path)

    for javascript in glob.glob("{}/*.js".format(project_shortname)):
        shutil.copy(javascript, deps_output_path)

    for css in glob.glob("{}/*.css".format(project_shortname)):
        shutil.copy(css, deps_output_path)

    for sourcemap in glob.glob("{}/*.map".format(project_shortname)):
        shutil.copy(sourcemap, deps_output_path)

def generate_imports(project_shortname, components):
    with open(os.path.join(project_shortname, '_imports_.py'), 'w') as f:
        imports_string = '{}\n\n{}'.format(
            '\n'.join(
                'from .{0} import {0}'.format(x) for x in components),
            '__all__ = [\n{}\n]'.format(
                ',\n'.join('    "{}"'.format(x) for x in components))
        )

        f.write(imports_string)


def required_props(props):
    """Pull names of required props from the props object.

    Parameters
    ----------
    props: dict

    Returns
    -------
    list
        List of prop names (str) that are required for the Component
    """
    return [prop_name for prop_name, prop in list(props.items())
            if prop['required']]


def create_docstring(component_name, props, description):
    """Create the Dash component docstring.

    Parameters
    ----------
    component_name: str
        Component name
    props: dict
        Dictionary with {propName: propMetadata} structure
    description: str
        Component description

    Returns
    -------
    str
        Dash component docstring
    """
    # Ensure props are ordered with children first
    props = reorder_props(props=props)

    return (
        """A{n} {name} component.\n{description}

Keyword arguments:\n{args}"""
    ).format(
        n='n' if component_name[0].lower() in ['a', 'e', 'i', 'o', 'u']
        else '',
        name=component_name,
        description=description,
        args='\n'.join(
            create_prop_docstring(
                prop_name=p,
                type_object=prop['type'] if 'type' in prop
                else prop['flowType'],
                required=prop['required'],
                description=prop['description'],
                default=prop.get('defaultValue'),
                indent_num=0,
                is_flow_type='flowType' in prop and 'type' not in prop)
            for p, prop in list(filter_props(props).items())))


def prohibit_events(props):
    """Events have been removed. Raise an error if we see dashEvents or
    fireEvents.

    Parameters
    ----------
    props: dict
        Dictionary with {propName: propMetadata} structure

    Raises
    -------
    ?
    """
    if 'dashEvents' in props or 'fireEvents' in props:
        raise NonExistentEventException(
            'Events are no longer supported by dash. Use properties instead, '
            'eg `n_clicks` instead of a `click` event.')


def parse_wildcards(props):
    """Pull out the wildcard attributes from the Component props.

    Parameters
    ----------
    props: dict
        Dictionary with {propName: propMetadata} structure

    Returns
    -------
    list
        List of Dash valid wildcard prefixes
    """
    list_of_valid_wildcard_attr_prefixes = []
    for wildcard_attr in ["data-*", "aria-*"]:
        if wildcard_attr in props:
            list_of_valid_wildcard_attr_prefixes.append(wildcard_attr[:-1])
    return list_of_valid_wildcard_attr_prefixes


def reorder_props(props):
    """If "children" is in props, then move it to the front to respect dash
    convention.

    Parameters
    ----------
    props: dict
        Dictionary with {propName: propMetadata} structure

    Returns
    -------
    dict
        Dictionary with {propName: propMetadata} structure
    """
    if 'children' in props:
        # Constructing an OrderedDict with duplicate keys, you get the order
        # from the first one but the value from the last.
        # Doing this to avoid mutating props, which can cause confusion.
        props = OrderedDict([('children', '')] + list(props.items()))

    return props


def filter_props(props):
    """Filter props from the Component arguments to exclude:

        - Those without a "type" or a "flowType" field
        - Those with arg.type.name in {'func', 'symbol', 'instanceOf'}

    Parameters
    ----------
    props: dict
        Dictionary with {propName: propMetadata} structure

    Returns
    -------
    dict
        Filtered dictionary with {propName: propMetadata} structure

    Examples
    --------
    ```python
    prop_args = {
        'prop1': {
            'type': {'name': 'bool'},
            'required': False,
            'description': 'A description',
            'flowType': {},
            'defaultValue': {'value': 'false', 'computed': False},
        },
        'prop2': {'description': 'A prop without a type'},
        'prop3': {
            'type': {'name': 'func'},
            'description': 'A function prop',
        },
    }
    # filtered_prop_args is now
    # {
    #    'prop1': {
    #        'type': {'name': 'bool'},
    #        'required': False,
    #        'description': 'A description',
    #        'flowType': {},
    #        'defaultValue': {'value': 'false', 'computed': False},
    #    },
    # }
    filtered_prop_args = filter_props(prop_args)
    ```
    """
    filtered_props = copy.deepcopy(props)

    for arg_name, arg in list(filtered_props.items()):
        if 'type' not in arg and 'flowType' not in arg:
            filtered_props.pop(arg_name)
            continue

        # Filter out functions and instances --
        # these cannot be passed from Python
        if 'type' in arg:  # These come from PropTypes
            arg_type = arg['type']['name']
            if arg_type in {'func', 'symbol', 'instanceOf'}:
                filtered_props.pop(arg_name)
        elif 'flowType' in arg:  # These come from Flow & handled differently
            arg_type_name = arg['flowType']['name']
            if arg_type_name == 'signature':
                # This does the same as the PropTypes filter above, but "func"
                # is under "type" if "name" is "signature" vs just in "name"
                if 'type' not in arg['flowType'] \
                        or arg['flowType']['type'] != 'object':
                    filtered_props.pop(arg_name)
        else:
            raise ValueError

    return filtered_props


# pylint: disable=too-many-arguments
def create_prop_docstring(prop_name, type_object, required, description,
                          default, indent_num, is_flow_type=False):
    """Create the Dash component prop docstring.

    Parameters
    ----------
    prop_name: str
        Name of the Dash component prop
    type_object: dict
        react-docgen-generated prop type dictionary
    required: bool
        Component is required?
    description: str
        Dash component description
    default: dict
        Either None if a default value is not defined, or
        dict containing the key 'value' that defines a
        default value for the prop
    indent_num: int
        Number of indents to use for the context block
        (creates 2 spaces for every indent)
    is_flow_type: bool
        Does the prop use Flow types? Otherwise, uses PropTypes

    Returns
    -------
    str
        Dash component prop docstring
    """
    py_type_name = js_to_py_type(
        type_object=type_object,
        is_flow_type=is_flow_type,
        indent_num=indent_num + 1)
    indent_spacing = '  ' * indent_num

    if default is None:
        default = ''
    else:
        default = default['value']

    if default in ['true', 'false']:
        default = default.title()

    is_required = 'optional'
    if required:
        is_required = 'required'
    elif default and default not in ['null', '{}', '[]']:
        is_required = 'default {}'.format(
            default.replace('\n', '\n' + indent_spacing)
        )

    if '\n' in py_type_name:
        return '{indent_spacing}- {name} (dict; {is_required}): ' \
            '{description}{period}' \
            '{name} has the following type: {type}'.format(
                indent_spacing=indent_spacing,
                name=prop_name,
                type=py_type_name,
                description=description.strip().strip('.'),
                period='. ' if description else '',
                is_required=is_required)
    return '{indent_spacing}- {name} ({type}' \
        '{is_required}){description}'.format(
            indent_spacing=indent_spacing,
            name=prop_name,
            type='{}; '.format(py_type_name) if py_type_name else '',
            description=(
                ': {}'.format(description) if description != '' else ''
            ),
            is_required=is_required)


def map_js_to_py_types_prop_types(type_object):
    """Mapping from the PropTypes js type object to the Python type."""

    def shape_or_exact():
        return 'dict containing keys {}.\n{}'.format(
            ', '.join(
                "'{}'".format(t) for t in list(type_object['value'].keys())
            ),
            'Those keys have the following types:\n{}'.format(
                '\n'.join(
                    create_prop_docstring(
                        prop_name=prop_name,
                        type_object=prop,
                        required=prop['required'],
                        description=prop.get('description', ''),
                        default=prop.get('defaultValue'),
                        indent_num=1
                    ) for prop_name, prop in
                    list(type_object['value'].items())))
            )

    return dict(
        array=lambda: 'list',
        bool=lambda: 'boolean',
        number=lambda: 'number',
        string=lambda: 'string',
        object=lambda: 'dict',
        any=lambda: 'boolean | number | string | dict | list',
        element=lambda: 'dash component',
        node=lambda: 'a list of or a singular dash '
                     'component, string or number',

        # React's PropTypes.oneOf
        enum=lambda: 'a value equal to: {}'.format(
            ', '.join(
                '{}'.format(str(t['value']))
                for t in type_object['value'])),

        # React's PropTypes.oneOfType
        union=lambda: '{}'.format(
            ' | '.join(
                '{}'.format(js_to_py_type(subType))
                for subType in type_object['value']
                if js_to_py_type(subType) != '')),

        # React's PropTypes.arrayOf
        arrayOf=lambda: (
            "list" + (" of {}".format(
                js_to_py_type(type_object["value"]) + 's'
                if js_to_py_type(type_object["value"]).split(' ')[0] != 'dict'
                else js_to_py_type(type_object["value"]).replace(
                        'dict', 'dicts', 1
                )
            )
                      if js_to_py_type(type_object["value"]) != ""
                      else "")
        ),

        # React's PropTypes.objectOf
        objectOf=lambda: (
            'dict with strings as keys and values of type {}'
            ).format(
                js_to_py_type(type_object['value'])),

        # React's PropTypes.shape
        shape=shape_or_exact,
        # React's PropTypes.exact
        exact=shape_or_exact
    )


def map_js_to_py_types_flow_types(type_object):
    """Mapping from the Flow js types to the Python type."""

    return dict(
        array=lambda: 'list',
        boolean=lambda: 'boolean',
        number=lambda: 'number',
        string=lambda: 'string',
        Object=lambda: 'dict',
        any=lambda: 'bool | number | str | dict | list',
        Element=lambda: 'dash component',
        Node=lambda: 'a list of or a singular dash '
                     'component, string or number',

        # React's PropTypes.oneOfType
        union=lambda: '{}'.format(
            ' | '.join(
                '{}'.format(js_to_py_type(subType))
                for subType in type_object['elements']
                if js_to_py_type(subType) != '')),

        # Flow's Array type
        Array=lambda: 'list{}'.format(
            ' of {}s'.format(
                js_to_py_type(type_object['elements'][0]))
            if js_to_py_type(type_object['elements'][0]) != ''
            else ''),

        # React's PropTypes.shape
        signature=lambda indent_num: 'dict containing keys {}.\n{}'.format(
            ', '.join("'{}'".format(d['key'])
                      for d in type_object['signature']['properties']),
            '{}Those keys have the following types:\n{}'.format(
                '  ' * indent_num,
                '\n'.join(
                    create_prop_docstring(
                        prop_name=prop['key'],
                        type_object=prop['value'],
                        required=prop['value']['required'],
                        description=prop['value'].get('description', ''),
                        default=prop.get('defaultValue'),
                        indent_num=indent_num,
                        is_flow_type=True)
                    for prop in type_object['signature']['properties']))),
    )


def js_to_py_type(type_object, is_flow_type=False, indent_num=0):
    """Convert JS types to Python types for the component definition.

    Parameters
    ----------
    type_object: dict
        react-docgen-generated prop type dictionary
    is_flow_type: bool
        Does the prop use Flow types? Otherwise, uses PropTypes
    indent_num: int
        Number of indents to use for the docstring for the prop

    Returns
    -------
    str
        Python type string
    """
    js_type_name = type_object['name']
    js_to_py_types = map_js_to_py_types_flow_types(type_object=type_object) \
        if is_flow_type \
        else map_js_to_py_types_prop_types(type_object=type_object)

    if 'computed' in type_object and type_object['computed'] \
            or type_object.get('type', '') == 'function':
        return ''
    if js_type_name in js_to_py_types:
        if js_type_name == 'signature':  # This is a Flow object w/ signature
            return js_to_py_types[js_type_name](indent_num)
        # All other types
        return js_to_py_types[js_type_name]()
    return ''


# This converts a string from snake case to camel case
# Not required for R package name to be in camel case,
# but probably more conventional this way
def snake_case_to_camel_case(namestring):
    s = namestring.split("_")
    return s[0] + "".join(w.capitalize() for w in s[1:])
