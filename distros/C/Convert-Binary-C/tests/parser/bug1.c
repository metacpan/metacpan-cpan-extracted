/*
 *  This must not parse correctly since unnamed enum
 *  members just don't make sense.
 */

enum enu { A };

struct foo {
  enum enu const;
};
