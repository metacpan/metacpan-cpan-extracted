/*
 * clay_perl_enums.h - Every Clay enum Clay::XS exports, listed once.
 *
 * CLAY_PERL_ENUM_<Group>(X) applies X to each member of one Clay enum, in
 * the order clay.h declares them. CLAY_PERL_ENUMS(SEQUENCE, FLAGS) names
 * every group, in export order, with its kind and the C type of its enum
 * (SEQUENCE(Group, Type) or FLAGS(Group, Type)):
 *
 *   SEQUENCE  The members are 0 .. N-1 in declaration order (checked at
 *             compile time below), so the last member is the largest
 *             value: CLAY_PERL_ENUM_MAX(Group).
 *   FLAGS     The members are bits and combinations of bits, meant to be
 *             OR-ed; their values do not follow their positions.
 *             CLAY_PERL_FLAGS_ALL(Group) is every member OR-ed together,
 *             the largest valid combination.
 *
 * Derived from these lists: the constant subs BOOT installs, the names
 * Clay::XS::_constant_names returns (lib/Clay/XS.xs, and from those
 * @EXPORT_OK), the groups Clay::XS::_constant_groups returns, and the
 * enum ranges of the struct schemas (src/marshal.c). t/00-load.t compares
 * every group with its enum in the patched clay.h, so a member Clay adds
 * fails the tests until it is listed. A new constant goes into its
 * group's list here and gets a POD entry in lib/Clay/XS.pm; a new group
 * also goes into CLAY_PERL_ENUMS.
 */

#ifndef CLAY_PERL_ENUMS_H
#define CLAY_PERL_ENUMS_H

#include "clay/clay.h"

#define CLAY_PERL_ENUM_LayoutDirection(X) \
    X(CLAY_LEFT_TO_RIGHT) X(CLAY_TOP_TO_BOTTOM) X(CLAY_LEFT_TO_RIGHT_WRAP) X(CLAY_BACK_TO_FRONT)

#define CLAY_PERL_ENUM_LineSizing(X) \
    X(CLAY_LINE_SIZING_GROW) X(CLAY_LINE_SIZING_FIT)

#define CLAY_PERL_ENUM_LayoutAlignmentX(X) \
    X(CLAY_ALIGN_X_LEFT) X(CLAY_ALIGN_X_RIGHT) X(CLAY_ALIGN_X_CENTER)

#define CLAY_PERL_ENUM_LayoutAlignmentY(X) \
    X(CLAY_ALIGN_Y_TOP) X(CLAY_ALIGN_Y_BOTTOM) X(CLAY_ALIGN_Y_CENTER)

#define CLAY_PERL_ENUM_SizingType(X) \
    X(CLAY__SIZING_TYPE_FIT) X(CLAY__SIZING_TYPE_GROW) X(CLAY__SIZING_TYPE_PERCENT) X(CLAY__SIZING_TYPE_FIXED)

#define CLAY_PERL_ENUM_TextWrapMode(X) \
    X(CLAY_TEXT_WRAP_WORDS) X(CLAY_TEXT_WRAP_NEWLINES) X(CLAY_TEXT_WRAP_NONE)

#define CLAY_PERL_ENUM_TextAlignment(X) \
    X(CLAY_TEXT_ALIGN_LEFT) X(CLAY_TEXT_ALIGN_CENTER) X(CLAY_TEXT_ALIGN_RIGHT)

#define CLAY_PERL_ENUM_FloatingAttachPointType(X) \
    X(CLAY_ATTACH_POINT_LEFT_TOP) X(CLAY_ATTACH_POINT_LEFT_CENTER) X(CLAY_ATTACH_POINT_LEFT_BOTTOM) \
    X(CLAY_ATTACH_POINT_CENTER_TOP) X(CLAY_ATTACH_POINT_CENTER_CENTER) X(CLAY_ATTACH_POINT_CENTER_BOTTOM) \
    X(CLAY_ATTACH_POINT_RIGHT_TOP) X(CLAY_ATTACH_POINT_RIGHT_CENTER) X(CLAY_ATTACH_POINT_RIGHT_BOTTOM)

#define CLAY_PERL_ENUM_PointerCaptureMode(X) \
    X(CLAY_POINTER_CAPTURE_MODE_CAPTURE) X(CLAY_POINTER_CAPTURE_MODE_PASSTHROUGH)

#define CLAY_PERL_ENUM_FloatingAttachToElement(X) \
    X(CLAY_ATTACH_TO_NONE) X(CLAY_ATTACH_TO_PARENT) X(CLAY_ATTACH_TO_ELEMENT_WITH_ID) X(CLAY_ATTACH_TO_ROOT)

#define CLAY_PERL_ENUM_FloatingClipToElement(X) \
    X(CLAY_CLIP_TO_NONE) X(CLAY_CLIP_TO_ATTACHED_PARENT)

#define CLAY_PERL_ENUM_RenderCommandType(X) \
    X(CLAY_RENDER_COMMAND_TYPE_NONE) X(CLAY_RENDER_COMMAND_TYPE_RECTANGLE) X(CLAY_RENDER_COMMAND_TYPE_BORDER) \
    X(CLAY_RENDER_COMMAND_TYPE_TEXT) X(CLAY_RENDER_COMMAND_TYPE_IMAGE) \
    X(CLAY_RENDER_COMMAND_TYPE_SCISSOR_START) X(CLAY_RENDER_COMMAND_TYPE_SCISSOR_END) \
    X(CLAY_RENDER_COMMAND_TYPE_OVERLAY_COLOR_START) X(CLAY_RENDER_COMMAND_TYPE_OVERLAY_COLOR_END) \
    X(CLAY_RENDER_COMMAND_TYPE_CUSTOM)

#define CLAY_PERL_ENUM_PointerDataInteractionState(X) \
    X(CLAY_POINTER_DATA_PRESSED_THIS_FRAME) X(CLAY_POINTER_DATA_PRESSED) \
    X(CLAY_POINTER_DATA_RELEASED_THIS_FRAME) X(CLAY_POINTER_DATA_RELEASED)

#define CLAY_PERL_ENUM_TransitionState(X) \
    X(CLAY_TRANSITION_STATE_IDLE) X(CLAY_TRANSITION_STATE_ENTERING) \
    X(CLAY_TRANSITION_STATE_TRANSITIONING) X(CLAY_TRANSITION_STATE_EXITING)

/* Flags: clay.h gives every member an explicit value, single bits and
 * named combinations (POSITION, DIMENSIONS, BOUNDING_BOX, BORDER). */
#define CLAY_PERL_ENUM_TransitionProperty(X) \
    X(CLAY_TRANSITION_PROPERTY_NONE) X(CLAY_TRANSITION_PROPERTY_X) X(CLAY_TRANSITION_PROPERTY_Y) \
    X(CLAY_TRANSITION_PROPERTY_POSITION) X(CLAY_TRANSITION_PROPERTY_WIDTH) X(CLAY_TRANSITION_PROPERTY_HEIGHT) \
    X(CLAY_TRANSITION_PROPERTY_DIMENSIONS) X(CLAY_TRANSITION_PROPERTY_BOUNDING_BOX) \
    X(CLAY_TRANSITION_PROPERTY_BACKGROUND_COLOR) X(CLAY_TRANSITION_PROPERTY_OVERLAY_COLOR) \
    X(CLAY_TRANSITION_PROPERTY_CORNER_RADIUS) X(CLAY_TRANSITION_PROPERTY_BORDER_COLOR) \
    X(CLAY_TRANSITION_PROPERTY_BORDER_WIDTH) X(CLAY_TRANSITION_PROPERTY_BORDER)

#define CLAY_PERL_ENUM_TransitionEnterTriggerType(X) \
    X(CLAY_TRANSITION_ENTER_SKIP_ON_FIRST_PARENT_FRAME) X(CLAY_TRANSITION_ENTER_TRIGGER_ON_FIRST_PARENT_FRAME)

#define CLAY_PERL_ENUM_TransitionExitTriggerType(X) \
    X(CLAY_TRANSITION_EXIT_SKIP_WHEN_PARENT_EXITS) X(CLAY_TRANSITION_EXIT_TRIGGER_WHEN_PARENT_EXITS)

#define CLAY_PERL_ENUM_TransitionInteractionHandlingType(X) \
    X(CLAY_TRANSITION_DISABLE_INTERACTIONS_WHILE_TRANSITIONING_POSITION) \
    X(CLAY_TRANSITION_ALLOW_INTERACTIONS_WHILE_TRANSITIONING_POSITION)

#define CLAY_PERL_ENUM_ExitTransitionSiblingOrdering(X) \
    X(CLAY_EXIT_TRANSITION_ORDERING_UNDERNEATH_SIBLINGS) X(CLAY_EXIT_TRANSITION_ORDERING_NATURAL_ORDER) \
    X(CLAY_EXIT_TRANSITION_ORDERING_ABOVE_SIBLINGS)

#define CLAY_PERL_ENUM_ErrorType(X) \
    X(CLAY_ERROR_TYPE_TEXT_MEASUREMENT_FUNCTION_NOT_PROVIDED) X(CLAY_ERROR_TYPE_ARENA_CAPACITY_EXCEEDED) \
    X(CLAY_ERROR_TYPE_ELEMENTS_CAPACITY_EXCEEDED) X(CLAY_ERROR_TYPE_TEXT_MEASUREMENT_CAPACITY_EXCEEDED) \
    X(CLAY_ERROR_TYPE_DUPLICATE_ID) X(CLAY_ERROR_TYPE_FLOATING_CONTAINER_PARENT_NOT_FOUND) \
    X(CLAY_ERROR_TYPE_PERCENTAGE_OVER_1) X(CLAY_ERROR_TYPE_INTERNAL_ERROR) \
    X(CLAY_ERROR_TYPE_UNBALANCED_OPEN_CLOSE) X(CLAY_ERROR_TYPE_HASH_MAP_CAPACITY_EXCEEDED) \
    X(CLAY_ERROR_TYPE_SIZING_GROUP_CYCLE)

#define CLAY_PERL_ENUMS(SEQUENCE, FLAGS) \
    SEQUENCE(LayoutDirection, Clay_LayoutDirection) \
    SEQUENCE(LineSizing, Clay_LineSizing) \
    SEQUENCE(LayoutAlignmentX, Clay_LayoutAlignmentX) \
    SEQUENCE(LayoutAlignmentY, Clay_LayoutAlignmentY) \
    SEQUENCE(SizingType, Clay__SizingType) \
    SEQUENCE(TextWrapMode, Clay_TextElementConfigWrapMode) \
    SEQUENCE(TextAlignment, Clay_TextAlignment) \
    SEQUENCE(FloatingAttachPointType, Clay_FloatingAttachPointType) \
    SEQUENCE(PointerCaptureMode, Clay_PointerCaptureMode) \
    SEQUENCE(FloatingAttachToElement, Clay_FloatingAttachToElement) \
    SEQUENCE(FloatingClipToElement, Clay_FloatingClipToElement) \
    SEQUENCE(RenderCommandType, Clay_RenderCommandType) \
    SEQUENCE(PointerDataInteractionState, Clay_PointerDataInteractionState) \
    SEQUENCE(TransitionState, Clay_TransitionState) \
    FLAGS(TransitionProperty, Clay_TransitionProperty) \
    SEQUENCE(TransitionEnterTriggerType, Clay_TransitionEnterTriggerType) \
    SEQUENCE(TransitionExitTriggerType, Clay_TransitionExitTriggerType) \
    SEQUENCE(TransitionInteractionHandlingType, Clay_TransitionInteractionHandlingType) \
    SEQUENCE(ExitTransitionSiblingOrdering, Clay_ExitTransitionSiblingOrdering) \
    SEQUENCE(ErrorType, Clay_ErrorType)

/* ---------------------------------------------------------------------------
 * Derived values.
 * ------------------------------------------------------------------------ */

#define CLAY_PERL_IGNORE_GROUP(group, type)

/* Compile-time check that every group names an existing C type. */
#define CLAY_PERL_CHECK_TYPE(group, type) typedef type clay_perl_type_of_##group;
CLAY_PERL_ENUMS(CLAY_PERL_CHECK_TYPE, CLAY_PERL_CHECK_TYPE)

/* The position of every member of a sequential group, and the group's
 * member count: CLAY_PERL_POSITION_OF_<member>, CLAY_PERL_COUNT_OF_<group>. */
#define CLAY_PERL_POSITION(member) CLAY_PERL_POSITION_OF_##member,
#define CLAY_PERL_DECLARE_POSITIONS(group, type) \
    enum { CLAY_PERL_ENUM_##group(CLAY_PERL_POSITION) CLAY_PERL_COUNT_OF_##group };
CLAY_PERL_ENUMS(CLAY_PERL_DECLARE_POSITIONS, CLAY_PERL_IGNORE_GROUP)

/* Compile-time check that every member of a sequential group has its
 * position as its value; a member out of order or with an explicit value
 * breaks the build here instead of giving the group a wrong maximum. */
#define CLAY_PERL_CHECK_POSITION(member) \
    typedef char clay_perl_##member##_is_at_its_position \
        [(int) (member) == (int) CLAY_PERL_POSITION_OF_##member ? 1 : -1];
#define CLAY_PERL_CHECK_POSITIONS(group, type) CLAY_PERL_ENUM_##group(CLAY_PERL_CHECK_POSITION)
CLAY_PERL_ENUMS(CLAY_PERL_CHECK_POSITIONS, CLAY_PERL_IGNORE_GROUP)

/* The last member of a sequential group: the largest valid value. */
#define CLAY_PERL_ENUM_MAX(group) (CLAY_PERL_COUNT_OF_##group - 1)

/* Every member of a flags group OR-ed together. */
#define CLAY_PERL_FLAG(member) | (member)
#define CLAY_PERL_FLAGS_ALL(group) (0 CLAY_PERL_ENUM_##group(CLAY_PERL_FLAG))

#endif /* CLAY_PERL_ENUMS_H */
