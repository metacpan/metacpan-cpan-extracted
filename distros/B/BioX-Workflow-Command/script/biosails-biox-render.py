#!/usr/bin/env python3

import argparse
import json
from jinja2 import Template
import pprint

def parse_json(args):
    with open(args.json) as f:
        object_data = json.load(f)
    with open(args.template, "r") as fh:
        template = Template(fh.read())
    # pprint.pprint(object_data)
    print(template.render(object_data))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Use Jinja templating for biosails render')
    parser.add_argument('-t', '--template', help='Path to template file', required=True)
    parser.add_argument('-j', '--json', help='Path to json object file', required=True)
    args = parser.parse_args()
    parse_json(args)
