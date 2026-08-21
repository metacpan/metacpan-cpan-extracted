add_library(histocli
    src/cli_common.c
    src/cli_main.c
    src/cmd_fill.c
    src/cmd_plot.c
    src/cmd_stats.c
    src/cmd_fit.c
    src/cmd_cmp.c
)

set_target_properties(histocli PROPERTIES
    OUTPUT_NAME "histocli"
    POSITION_INDEPENDENT_CODE ON
)

target_include_directories(histocli PUBLIC
    $<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}/include>
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
    $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
)

target_link_libraries(histocli PUBLIC histo)

# Alias for backwards compatibility with tests
add_library(histo_tools_lib ALIAS histocli)

add_executable(histo-cli
    src/main.c
)

set_target_properties(histo-cli PROPERTIES OUTPUT_NAME "histo")

target_include_directories(histo-cli PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/include
    ${PROJECT_SOURCE_DIR}/include
)

target_link_libraries(histo-cli PRIVATE histocli)

# Create symlink aliases in build directory
set(TOOL_ALIASES histo-fill histo-plot histo-stats histo-fit histo-cmp)

foreach(alias ${TOOL_ALIASES})
    add_custom_command(TARGET histo-cli POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E create_symlink $<TARGET_FILE_NAME:histo-cli> ${CMAKE_CURRENT_BINARY_DIR}/${alias}
        COMMENT "Creating CLI alias symlink ${alias} -> histo"
    )
endforeach()

install(TARGETS histocli histo-cli
    EXPORT libhistoTargets
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
)

foreach(alias ${TOOL_ALIASES})
    install(CODE "
        execute_process(
            COMMAND \${CMAKE_COMMAND} -E create_symlink histo \"\$ENV{DESTDIR}\${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_BINDIR}/${alias}\"
        )
    ")
endforeach()
